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
if [ -z "$NFT_CONTRACT_ADDRESS" ] 
then
    echo "NFT_CONTRACT_ADDRESS is not set"
    echo "You can run the script by setting the variables at the beginning: NFT_CONTRACT_ADDRESS=0x mintNft.sh"
    exit 0
fi

# Mint NFT
echo "Minting NFT..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "mint()"

# NFT_CONTRACT_ADDRESS= ./scripts/mintNft.sh
