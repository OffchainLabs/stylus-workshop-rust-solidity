// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "./oz/ERC20.sol";

interface NftContract {
    function mintTo(address) external;
}

contract MyToken is ERC20 {
    address private _nftContractAddress;
    
    error NftContractAddressAlreadySet(address nftContractAddress);
    error NftContractNotSet();

    constructor() ERC20("MyToken", "MTK") {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    // One-time setters
    function setNftContractAddress(address newNftContractAddress) public {
        if (_nftContractAddress != address(0)) {
            revert NftContractAddressAlreadySet(_nftContractAddress);
        }
        _nftContractAddress = newNftContractAddress;
    }

    // Mint NFT from the ERC-20 contract
    function mintNft() public {
        if (_nftContractAddress == address(0)) {
            revert NftContractNotSet();
        }

        NftContract(_nftContractAddress).mintTo(msg.sender);
    }
}
