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
if [ -z "$ERC20_CONTRACT_ADDRESS" ] 
then
    echo "ERC20_CONTRACT_ADDRESS is not set"
    echo "You can run the script by setting the variables at the beginning: ERC20_CONTRACT_ADDRESS=0x mintNftFromTokenContract.sh"
    exit 0
fi

# Mint NFT
echo "Minting NFT from ERC-20 contract..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $ERC20_CONTRACT_ADDRESS "mintNft()"

# ERC20_CONTRACT_ADDRESS= ./scripts/mintNftFromTokenContract.sh
