#!/bin/bash

# ------------- #
# Configuration #
# ------------- #

# Load variables from .env file
set -o allexport
source scripts/.env
set +o allexport

# -------------- #
# Initial checks #
# -------------- #
if [ -z "$PRIVATE_KEY" ] || [ -z "$ADDRESS" ]
then
    echo "You need to provide the PRIVATE_KEY and the ADDRESS of the deployer"
    exit 0
fi

if [ -z "$ART_CONTRACT_ADDRESS" ] || [ -z "$NFT_CONTRACT_ADDRESS" ] || [ -z "$ERC20_CONTRACT_ADDRESS" ]
then
    echo "You need to provide the addresses of the deployed contracts: ART_CONTRACT_ADDRESS, NFT_CONTRACT_ADDRESS, ERC20_CONTRACT_ADDRESS"
    exit 0
fi

# ----- #
# Tests #
# ----- #
# Initial check
echo ""
echo "-----------"
echo "Start tests"
echo "-----------"
echo "Initial checks..."
nft_balance_start=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
nft_owner_start=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "ownerOf(uint256) (address)" 0 2>/dev/null)
erc20_balance_start=$(cast call --rpc-url $RPC_URL $ERC20_CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "Initial NFT balance: $nft_balance_start"
echo "Initial NFT owner (token id 0): $nft_owner_start"
echo "Initial ERC-20 balance: $erc20_balance_start"
echo ""

# Try to mint NFT (should fail)
echo "Trying to mint NFT (it should fail)..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "mint()"
echo ""

# Mint ERC-20 tokens
echo "Minting ERC-20 tokens..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $ERC20_CONTRACT_ADDRESS "mint(uint256)" 20
echo ""

# Mint NFTs
echo "Minting NFTs..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "mint()"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "mint()"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "mint()"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "mint()"

# Minting check
nft_balance_after_minting=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
nft_owner_after_minting=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "ownerOf(uint256) (address)" 0)
erc20_balance_after_minting=$(cast call --rpc-url $RPC_URL $ERC20_CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "NFT balance after minting: $nft_balance_after_minting"
echo "NFT owner after minting (token id 0): $nft_owner_after_minting"
echo "ERC-20 balance after minting: $erc20_balance_after_minting"
echo ""

# Generate art
echo "Generating art..."
nft_art_image=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "tokenURI(uint256) (string)" 0)
echo "NFT image: $nft_art_image"
echo ""

# Transfering
echo "Transfering NFTs..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "transferFrom(address,address,uint256)" $ADDRESS $RECEIVER_ADDRESS 0
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "transferFrom(address,address,uint256)" $ADDRESS $RECEIVER_ADDRESS 1

# Transfering check
balance_minter_after_transfering=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
balance_receiver_after_transfering=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "balanceOf(address) (uint256)" $RECEIVER_ADDRESS)
owner_after_transfering=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "ownerOf(uint256) (address)" 0)
echo "Balance after transfering (minter): $balance_minter_after_transfering"
echo "Balance after transfering (receiver): $balance_receiver_after_transfering"
echo "Owner after transfering (token id 0): $owner_after_transfering"
echo ""

# Generate art (again)
echo "Generating art again..."
nft_art_image_after_transfering=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "tokenURI(uint256) (string)" 0)
echo "NFT image (after transfering): $nft_art_image_after_transfering"
echo ""

# Generate art directly from the Art contract
echo "Generating art from the Art contract..."
raw_art_image=$(cast call --rpc-url $RPC_URL $ART_CONTRACT_ADDRESS "generateArt(uint256,address) (string)" 0 $RECEIVER_ADDRESS)
echo "Image (from the Art contract): $raw_art_image"
echo ""

# Mint NFT directly from ERC-20 contract
echo "Minting NFT from the ERC-20 contract..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $ERC20_CONTRACT_ADDRESS "mintNft()"
balance_after_minting_from_erc20=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "Balance after minting from ERC20: $balance_after_minting_from_erc20"
echo ""