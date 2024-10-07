#!/bin/bash

# ------------- #
# Configuration #
# ------------- #

# Load variables from .env file
set -o allexport
source scripts/.env
set +o allexport

# Optionally, add the contract addresses here
# export ART_CONTRACT_ADDRESS=0xd1aa1b583f2c086d0964600e0c79a95acbc30a65
# export NFT_CONTRACT_ADDRESS=0xd01207dd6eb9359f7572f658de0cb4ec98858da5
# export ERC20_CONTRACT_ADDRESS=0xb8F30164C4D1f62155F7a1115E68e605069689E4

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

# ---------------------- #
# Contract configuration #
# ---------------------- #
echo ""
echo "----------------------"
echo "Initializing contracts"
echo "----------------------"

# Initialize NFT contract (will also initialize the Art contract)
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "initialize(address, address)" $ART_CONTRACT_ADDRESS $ERC20_CONTRACT_ADDRESS

# Final result
echo ""
echo "Contracts deployed and initialized"
echo "NFT contract deployed and activated at address: $NFT_CONTRACT_ADDRESS"
echo "Art contract deployed and activated at address: $ART_CONTRACT_ADDRESS"
echo "ERC20 contract deployed at address: $ERC20_CONTRACT_ADDRESS"
