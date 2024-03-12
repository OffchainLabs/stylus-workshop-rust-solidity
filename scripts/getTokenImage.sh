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
    echo "You can run the script by setting the variables at the beginning: NFT_CONTRACT_ADDRESS=0x getTokenImage.sh"
    exit 0
fi

# Generate art
echo "Generating art..."
nft_art_image=$(cast call --rpc-url $RPC_URL $NFT_CONTRACT_ADDRESS "tokenUri(uint256) (string)" 0)
echo "NFT image: $nft_art_image"

# Create a PNG file
filename="images/tokenImage_0_$(date +%s).png"
base64 -d <<< ${nft_art_image/"data:image/png;base64,"/} > $filename

# NFT_CONTRACT_ADDRESS= ./scripts/getTokenImage.sh
