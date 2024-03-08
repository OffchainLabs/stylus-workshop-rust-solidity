/// Implements FNV-1a hashing (not cryptographically secure)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FnvHasher(pub u64);

const FNV_PRIME: u64 = 1099511628211;

impl Default for FnvHasher {
    fn default() -> Self {
        FnvHasher(14695981039346656037)
    }
}

impl FnvHasher {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn update(&mut self, input: &[u8]) {
        for &byte in input {
            self.0 ^= byte as u64;
            self.0 = self.0.wrapping_mul(FNV_PRIME);
        }
    }

    pub fn output(self) -> u64 {
        self.0
    }
}