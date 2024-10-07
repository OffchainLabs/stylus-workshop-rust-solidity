#!/bin/bash

# ------------- #
# Configuration #
# ------------- #

# Load variables from .env file
set -o allexport
source scripts/.env
set +o allexport

# Helper constants
ART_DEPLOYMENT_DATA_FILE=art_deployment_data
NFT_DEPLOYMENT_DATA_FILE=nft_deployment_data
ERC20_DEPLOYMENT_DATA_FILE=erc20_deployment_data

# -------------- #
# Initial checks #
# -------------- #
if [ -z "$PRIVATE_KEY" ] || [ -z "$ADDRESS" ]
then
    echo "You need to provide the PRIVATE_KEY and the ADDRESS of the deployer"
    exit 0
fi

# ----------------- #
# Deployment of Art #
# ----------------- #
echo ""
echo "----------------------"
echo "Deploying Art contract"
echo "----------------------"

# Move to nft folder
cd art

# Deploy contract
cargo stylus deploy -e $RPC_URL --private-key $PRIVATE_KEY --no-verify > $ART_DEPLOYMENT_DATA_FILE

# ----------------- #
# Deployment of NFT #
# ----------------- #
echo ""
echo "----------------------"
echo "Deploying NFT contract"
echo "----------------------"

# Move to nft folder
cd ../nft

# Deploy contract
cargo stylus deploy -e $RPC_URL --private-key $PRIVATE_KEY --no-verify > $NFT_DEPLOYMENT_DATA_FILE


# -------------------- #
# Deployment of ERC-20 #
# -------------------- #
echo ""
echo "-------------------------"
echo "Deploying ERC-20 contract"
echo "-------------------------"

# Move to nft folder
cd ../erc20

# Compile and deploy ERC-20 contract
forge build
forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY src/MyToken.sol:MyToken > $ERC20_DEPLOYMENT_DATA_FILE


# ---------------- #
# Show all results #
# ---------------- #
cd ..

echo ""
echo "------------------"
echo "Displaying results"
echo "------------------"
echo ""
echo "Art contract deployment:"
cat art/$ART_DEPLOYMENT_DATA_FILE
echo ""
echo "------------------------"
echo ""
echo "Nft contract deployment:"
cat nft/$NFT_DEPLOYMENT_DATA_FILE
echo ""
echo "------------------------"
echo ""
echo "Erc-20 contract deployment:"
cat erc20/$ERC20_DEPLOYMENT_DATA_FILE

rm art/$ART_DEPLOYMENT_DATA_FILE
rm nft/$NFT_DEPLOYMENT_DATA_FILE
rm erc20/$ERC20_DEPLOYMENT_DATA_FILE
