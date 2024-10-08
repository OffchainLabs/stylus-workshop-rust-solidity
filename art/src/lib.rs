extern crate alloc;

// Modules and imports
mod utils;
mod art;

use stylus_sdk::{
    prelude::*,
    call::Call,
    storage::StorageAddress,
    alloy_primitives::{Address, U256}
};
use alloy_sol_types::sol;
use base64::Engine;
use fastrand::Rng;
use crate::art::{Color, Image, Cell};
use crate::utils::FnvHasher;

/// Generates the image for a given NFT token ID
pub fn gen_art(address: Address, token_id: U256) -> Image<32, 32> {
    let mut hasher = FnvHasher::new();
    hasher.update(token_id.as_le_slice());
    hasher.update(address.as_slice());
    let mut rng = Rng::with_seed(hasher.output());

    let bg_color = Color::from_hex(0xe3066e);
    let fg_color = Color {
        red: rng.u8(..),
        green: rng.u8(..),
        blue: rng.u8(..),
    };

    let mut image = Image::new(bg_color);

    image.draw_gradient(Color::from_hex(0xff0000), Color::from_hex(0x0000ff));
    image.draw_line(Cell::new(4, 4), Cell::new(4, 6), fg_color);
    image.draw_line(Cell::new(10, 4), Cell::new(10, 6), fg_color);
    image.draw_ellipse(Cell::new(7, 9), 3, 3, [false, false, true, true], fg_color);
    image
}

// Solidity interface for the NFT contract
sol_interface! {
    interface Nft {
        function ownerOf(uint256 token_id) external returns(address);
    }
}

/// Entrypoint for Art contract
#[storage]
#[entrypoint]
pub struct StylusNFTArt {
    /// The NFT contract that this Art contract delivers the art for
    token_contract_address: StorageAddress,
}

// Declares Solidity error types
sol! {
    error AlreadyInitialized();
    error ExternalCallFailed();
}

/// Error definitions
#[derive(SolidityError)]
pub enum StylusNftArtError {
    /// Contract is already initialized
    AlreadyInitialized(AlreadyInitialized),
    /// A call to an external contract failed
    ExternalCallFailed(ExternalCallFailed),
}

// Contract implementation
#[public]
impl StylusNFTArt {
    /// Generates the art of a specific token_id
    #[selector(name = "generateArt")]
    pub fn generate_art(&mut self, token_id: U256) -> Result<String, StylusNftArtError> {
        // Call the NFT contract to get the owner
        let token_contract_address = self.token_contract_address.get();
        let token_contract = Nft::new(token_contract_address);
        let config = Call::new();
        let owner = token_contract
            .owner_of(config, token_id)
            .map_err(|_e| StylusNftArtError::ExternalCallFailed(ExternalCallFailed {}))?;

        let image_str = self.generate_art_with_owner(token_id, owner)?;
        Ok(image_str)
    }
    
    /// Generates the art of a specific token_id and a specific address (assuming it's the owner)
    #[selector(name = "generateArt")]
    pub fn generate_art_with_owner(&mut self, token_id: U256, owner: Address) -> Result<String, StylusNftArtError> {
        let image = gen_art(owner, token_id);
        let image_png = image.make_png();
        let mut image_str = String::from("data:image/png;base64,");
        base64::engine::general_purpose::STANDARD.encode_string(&image_png, &mut image_str);
        Ok(image_str)
    }

    /// Initialize program
    pub fn initialize(&mut self, token_contract_address: Address) -> Result<(), StylusNftArtError> {
        let current_contract = self.token_contract_address.get();
        if !current_contract.is_zero() {
            return Err(StylusNftArtError::AlreadyInitialized(AlreadyInitialized {}));
        }
        self.token_contract_address.set(token_contract_address);
        Ok(())
    }

    /// Getter for the art contract address
    pub fn get_token_contract_address(&mut self) -> Result<Address, StylusNftArtError> {
        Ok(self.token_contract_address.get())
    }
}
