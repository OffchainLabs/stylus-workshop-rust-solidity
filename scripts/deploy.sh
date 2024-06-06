#!/bin/bash

# ------------- #
# Configuration #
# ------------- #

# Load variables from .env file
set -o allexport
source scripts/.env
set +o allexport

# Helper constants
DEPLOYMENT_TX_DATA_FILE=deployment_tx_data
ACTIVATION_TX_DATA_FILE=activation_tx_data
DEPLOY_CONTRACT_RESULT_FILE=create_contract_result

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
cargo stylus deploy -e $RPC_URL --private-key $PRIVATE_KEY > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address (last "sed" command removes the color codes of the output)
# (Note: last regex obtained from https://stackoverflow.com/a/51141872)
art_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 2p)
if ! [[ $art_contract_address_str == *0x* ]]
then
    # When the program needs activation, the output of the command is slightly different
    art_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 3p)
fi
art_contract_address_array=($art_contract_address_str)
art_contract_address=$(echo ${art_contract_address_array[2]} | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')
rm $DEPLOY_CONTRACT_RESULT_FILE

# Final result
echo "Art contract deployed and activated at address: $art_contract_address"


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
cargo stylus deploy -e $RPC_URL --private-key $PRIVATE_KEY > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address (last "sed" command removes the color codes of the output)
# (Note: last regex obtained from https://stackoverflow.com/a/51141872)
nft_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 2p)
if ! [[ $nft_contract_address_str == *0x* ]]
then
    # When the program needs activation, the output of the command is slightly different
    nft_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 3p)
fi
nft_contract_address_array=($nft_contract_address_str)
nft_contract_address=$(echo ${nft_contract_address_array[2]} | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')
rm $DEPLOY_CONTRACT_RESULT_FILE

# Final result
echo "NFT contract deployed and activated at address: $nft_contract_address"


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
forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY src/MyToken.sol:MyToken > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address
erc20_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 3p)
erc20_contract_address_array=($erc20_contract_address_str)
erc20_contract_address=${erc20_contract_address_array[2]}

# Remove all files
rm $DEPLOY_CONTRACT_RESULT_FILE

# Final result
echo "ERC20 contract deployed at address: $erc20_contract_address"


# ---------------------- #
# Contract configuration #
# ---------------------- #
echo ""
echo "----------------------"
echo "Initializing contracts"
echo "----------------------"

# Initialize NFT contract (will also initialize the Art contract)
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $nft_contract_address "initialize(address, address)" $art_contract_address $erc20_contract_address

# Final result
echo ""
echo "Contracts deployed and initialized"
echo "NFT contract deployed and activated at address: $nft_contract_address"
echo "Art contract deployed and activated at address: $art_contract_address"
echo "ERC20 contract deployed at address: $erc20_contract_address"
