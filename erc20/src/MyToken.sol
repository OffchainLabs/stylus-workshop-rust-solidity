// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "./oz/ERC20.sol";

interface NftContract {
    function mintFromErc20Contract(address) external;
}

contract MyToken is ERC20 {
    address private _nftContractAddress;
    uint256 private _minBalanceToMintNft;
    
    error NftContractAddressAlreadySet(address nftContractAddress);
    error NftContractNotSet();
    error MinBalanceToMintNftAlreadySet(uint256 minBalanceToMint);
    error NotEnoughBalanceToMintNft(uint256 balance, uint256 expected);

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

    function setMinBalanceToMintNft(uint256 minBalanceToMint) public {
        if (_minBalanceToMintNft > 0) {
            revert MinBalanceToMintNftAlreadySet(_minBalanceToMintNft);
        }

        _minBalanceToMintNft = minBalanceToMint;
    }

    // Mint NFT from the ERC-20 contract
    function mintNft() public {
        if (_nftContractAddress == address(0)) {
            revert NftContractNotSet();
        }

        uint256 minterBalance = balanceOf(msg.sender);
        if (minterBalance <= _minBalanceToMintNft) {
            revert NotEnoughBalanceToMintNft(minterBalance, _minBalanceToMintNft);
        }

        NftContract(_nftContractAddress).mintFromErc20Contract(msg.sender);
    }
}
