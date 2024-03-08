//! Utilities.
use alloc::{boxed::Box, vec, vec::Vec};
use hex_literal::hex;

/// Represents a cell on the grid.
pub struct Cell {
    x: usize,
    y: usize,
}

impl Cell {
    pub fn new(x: usize, y: usize) -> Cell {
        Cell { x, y }
    }
}

/// Represents an RGB color
#[derive(Default, Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Color {
    pub red: u8,
    pub green: u8,
    pub blue: u8,
}

impl Color {
    pub const fn from_hex(value: usize) -> Self {
        Self {
            red: (value >> 16) as u8,
            green: (value >> 8) as u8,
            blue: value as u8,
        }
    }

    pub const fn to_hex(&self) -> usize {
        (self.red as usize) << 16 | (self.green as usize) << 8 | self.blue as usize
    }
}

/// A grid of pixels `R` rows by `C` columns.
pub type Pixels<const R: usize, const C: usize> = Box<[[Color; C]; R]>;

/// If true, never leaves a line connected by just a diagonal
const THICK_LINES: bool = false;

/// Represents an image.
pub struct Image<const R: usize, const C: usize> {
    pub pixels: Pixels<R, C>,
}

/// Doesn't actually compress, just changes formats.
///
/// Equivalent to zlib compression level 0.
pub fn zlib_format(mut data: &[u8]) -> Vec<u8> {
    if data.is_empty() {
        return hex!("789c030000000001").to_vec();
    }
    let mut out = vec![0x08, 0x1d];
    let checksum = adler::adler32_slice(data);
    // Split the data into max sized raw chunks
    while !data.is_empty() {
        let chunk;
        (chunk, data) = data.split_at(core::cmp::min(data.len(), 65535));
        let last_block = data.is_empty() as u8;

        // Raw block is indicated by the next two bits being "00"
        out.push(last_block); // The other bits will be 0

        // Write the length of the block (LSB first)
        out.extend((chunk.len() as u16).to_le_bytes());

        // Write the one's complement of the length (for raw blocks)
        out.extend((!chunk.len() as u16).to_le_bytes());

        // Write the raw data
        out.extend_from_slice(chunk);
    }
    out.extend(checksum.to_be_bytes());
    out
}

// Drawing algorithms are from http://members.chello.at/~easyfilter/Bresenham.pdf
impl<const R: usize, const C: usize> Image<R, C> {
    /// Creates a new image with a default background color.
    pub fn new(bg_color: Color) -> Image<R, C> {
        Image {
            pixels: Box::new([[bg_color; C]; R]),
        }
    }

    /// Draws a line from `start` to `end` with the given `color`
    pub fn draw_line(&mut self, start: Cell, end: Cell, color: Color) {
        let dx = end.x.abs_diff(start.x) as isize;
        let dy = -(end.y.abs_diff(start.y) as isize);
        let sx = if end.x > start.x { 1 } else { -1 };
        let sy = if end.y > start.y { 1 } else { -1 };
        let mut error = dx + dy;
        let mut x = start.x;
        let mut y = start.y;
        self.pixels[y][x] = color;
        while x != end.x || y != end.y {
            let error2 = error * 2;
            if error2 >= dy {
                debug_assert!(x != end.x);
                error += dy;
                x = x.saturating_add_signed(sx);
                if THICK_LINES {
                    self.pixels[y][x] = color;
                }
            }
            if error2 <= dx {
                debug_assert!(y != end.y);
                error += dx;
                y = y.saturating_add_signed(sy);
                if THICK_LINES {
                    self.pixels[y][x] = color;
                }
            }
            if !THICK_LINES {
                self.pixels[y][x] = color;
            }
        }
    }

    /// Draws an ellipse centered at `center` with width `a` and height `b`.
    /// Only draws the quadrants set to `true` in `draw_quadrants`.
    /// `draw_quadrants` is an array of quadrant I through quadrant IV; i.e.
    /// it starts in the top right and goes counter-clockwise.
    pub fn draw_ellipse(
        &mut self,
        center: Cell,
        a: usize,
        b: usize,
        draw_quadrants: [bool; 4],
        color: Color,
    ) {
        let mut x = a; // IV. quadrant
        let mut y = 0;
        let mut dx = (1 - 2 * x as isize) * (b * b) as isize;
        let mut dy = (x * x) as isize;
        let mut error = dx + dy;
        // Draws coordinates if in-bound
        let mut draw = |x: Option<usize>, y: Option<usize>| {
            if let (Some(x), Some(y)) = (x, y) {
                if x < C && y < R {
                    self.pixels[y][x] = color;
                }
            }
        };
        loop {
            if draw_quadrants[0] {
                // I. Quadrant
                draw(center.x.checked_add(x), center.y.checked_sub(y));
            }
            if draw_quadrants[1] {
                // II. Quadrant
                draw(center.x.checked_sub(x), center.y.checked_sub(y));
            }
            if draw_quadrants[2] {
                // III. Quadrant
                draw(center.x.checked_sub(x), center.y.checked_add(y));
            }
            if draw_quadrants[3] {
                // IV. Quadrant
                draw(center.x.checked_add(x), center.y.checked_add(y));
            }
            let error2 = error * 2;
            if error2 >= dx {
                if x == 0 {
                    break;
                }
                x -= 1;
                dx += (2 * b * b) as isize;
                error += dx;
            }
            if error2 <= dy {
                y += 1;
                dy += (2 * a * a) as isize;
                error += dy;
            }
        }
        // Handle very flat ellipses (a=1)
        while y < b {
            y += 1;
            if draw_quadrants[0] || draw_quadrants[1] {
                draw(Some(center.x), center.y.checked_sub(y));
            }
            if draw_quadrants[2] || draw_quadrants[3] {
                draw(Some(center.x), center.y.checked_add(y));
            }
        }
    }

    /// Draws a line from `start` to `end` with the given `color`
    pub fn draw_gradient(&mut self, start: Color, end: Color) {
        for x in 0..C {
            for y in 0..R {
                let blend = 100 * (x + y) / (C + R);
                let lerp = |x, y| ((x as usize * blend + y as usize * (100 - blend)) / 100) as u8;

                let color = Color {
                    red: lerp(start.red, end.red),
                    green: lerp(start.green, end.green),
                    blue: lerp(start.blue, end.blue),
                };
                self.pixels[y][x] = color;
            }
        }
    }

    fn uncompressed_pixel_data(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(R * (1 + C * 3));
        for row in &*self.pixels {
            out.push(0); // Filter type: none
            for pixel in row {
                out.push(pixel.red);
                out.push(pixel.green);
                out.push(pixel.blue);
            }
        }
        out
    }

    /// Returns the bytes of the PNG formatted image 
    pub fn make_png(&self) -> Vec<u8> {
        let idat = zlib_format(&self.uncompressed_pixel_data());
        let mut out = Vec::new();
        out.extend(hex!("89504E470D0A1A0A")); // PNG signature
        let mut append_chunk = |name: &[u8; 4], chunk: &[u8]| {
            out.extend((chunk.len() as u32).to_be_bytes());
            let start = out.len();
            out.extend(name);
            out.extend(chunk);
            let crc = crc::Crc::<u32>::new(&crc::CRC_32_ISO_HDLC);
            out.extend(crc.checksum(&out[start..]).to_be_bytes());
        };
        let mut ihdr = Vec::new();
        ihdr.extend((C as u32).to_be_bytes());
        ihdr.extend((R as u32).to_be_bytes());
        ihdr.push(8); // bit depth
        ihdr.push(2); // colour type: truecolour
        ihdr.push(0); // compression: deflate
        ihdr.push(0); // filter method: adapative
        ihdr.push(0); // interlace: no interlace
        append_chunk(b"IHDR", &ihdr);
        drop(ihdr);
        append_chunk(b"IDAT", &idat);
        append_chunk(b"IEND", &[]);
        out
    }
}
