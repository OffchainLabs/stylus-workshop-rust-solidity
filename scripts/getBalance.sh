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
    echo "You can run the script by setting the variables at the beginning: NFT_CONTRACT_ADDRESS=0x getBalance.sh"
    exit 0
fi

# Get balance
echo "Get balance of account"
balance=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "NFT balance: $balance"

# NFT_CONTRACT_ADDRESS= ./scripts/getBalance.sh
