// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "./oz/ERC20.sol";

interface NftContract {
    function mint() external;
}

contract MyToken is ERC20 {
    address private nftContractAddress;
    
    error NftContractAddressAlreadySet(address nftContractAddress);
    error NftContractNotSet();

    constructor() ERC20("MyToken", "MTK") {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function setNftContractAddress(address newNftContractAddress) public {
        if (nftContractAddress != address(0)) {
            revert NftContractAddressAlreadySet(nftContractAddress);
        }
        nftContractAddress = newNftContractAddress;
    }

    function mintNft() public {
        if (nftContractAddress == address(0)) {
            revert NftContractNotSet();
        }

        NftContract(nftContractAddress).mint();
    }
}
