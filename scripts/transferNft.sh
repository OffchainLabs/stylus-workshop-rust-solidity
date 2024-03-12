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
    echo "You can run the script by setting the variables at the beginning: NFT_CONTRACT_ADDRESS=0x transferNft.sh"
    exit 0
fi

# Transfer NFT
echo "Transfering NFTs..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $NFT_CONTRACT_ADDRESS "transferFrom(address,address,uint256)" $ADDRESS $RECEIVER_ADDRESS 0

# NFT_CONTRACT_ADDRESS= ./scripts/transferNft.sh
