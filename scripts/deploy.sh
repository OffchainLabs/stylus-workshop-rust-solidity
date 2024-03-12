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

# Prepare transactions data
cargo stylus deploy -e $RPC_URL --private-key $PRIVATE_KEY --dry-run --output-tx-data-to-dir .

# Get contract bytecode
bytecode=$(cat $DEPLOYMENT_TX_DATA_FILE | od -An -v -tx1 | tr -d ' \n')
rm $DEPLOYMENT_TX_DATA_FILE

# Send transaction to blockchain
echo "Sending contract creation transaction..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY --create $bytecode > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address
art_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 4p)
art_contract_address_array=($art_contract_address_str)
art_contract_address=${art_contract_address_array[1]}
rm $DEPLOY_CONTRACT_RESULT_FILE

# Send activation transaction
echo "Sending activation transaction..."
if [ -f ./$ACTIVATION_TX_DATA_FILE ]; then
    cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY 0x0000000000000000000000000000000000000071 "activateProgram(address)" $art_contract_address > /dev/null
    rm $ACTIVATION_TX_DATA_FILE
else
    echo "Not needed, contract already activated"
fi

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

# Prepare transactions data
cargo stylus deploy -e $RPC_URL --private-key $PRIVATE_KEY --dry-run --output-tx-data-to-dir .

# Get contract bytecode
bytecode=$(cat $DEPLOYMENT_TX_DATA_FILE | od -An -v -tx1 | tr -d ' \n')
rm $DEPLOYMENT_TX_DATA_FILE

# Send transaction to blockchain
echo "Sending contract creation transaction..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY --create $bytecode > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address
nft_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 4p)
nft_contract_address_array=($nft_contract_address_str)
nft_contract_address=${nft_contract_address_array[1]}
rm $DEPLOY_CONTRACT_RESULT_FILE

# Send activation transaction
echo "Sending activation transaction..."
if [ -f ./$ACTIVATION_TX_DATA_FILE ]; then
    cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY 0x0000000000000000000000000000000000000071 "activateProgram(address)" $nft_contract_address > /dev/null
    rm $ACTIVATION_TX_DATA_FILE
else
    echo "Not needed, contract already activated"
fi

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
