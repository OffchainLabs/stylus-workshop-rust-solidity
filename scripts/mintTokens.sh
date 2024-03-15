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
    echo "You can run the script by setting the variables at the beginning: ERC20_CONTRACT_ADDRESS=0x mintTokens.sh"
    exit 0
fi

# Mint ERC-20 tokens
echo "Minting ERC-20 tokens..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $ERC20_CONTRACT_ADDRESS "mint(uint256)" 20

# ERC20_CONTRACT_ADDRESS= ./scripts/mintTokens.sh
