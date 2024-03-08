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

# Environment variables
[ "$ENV" = "local" ] && RPC_URL=http://localhost:8547 || RPC_URL=https://stylus-testnet.arbitrum.io/rpc
[ "$ENV" = "local" ] && MINTER_PK=0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659 || MINTER_PK=$TESTNET_PK
[ "$ENV" = "local" ] && USER=0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E || USER=$TESTNET_ADDRESS

# Other variables
RECEIVER=$RECEIVER_ADDRESS

# -------------- #
# Initial checks #
# -------------- #
if [ "$ENV" = "testnet" ]
then
    if [ -z "$TESTNET_PK" ] || [ -z "$TESTNET_ADDRESS" ]
    then
        echo "You need to provide the private key and the address for the testnet deployer"
        exit 0
    fi
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
cargo stylus deploy -e $RPC_URL --private-key $MINTER_PK --dry-run --output-tx-data-to-dir .

# Get contract bytecode
bytecode=$(cat $DEPLOYMENT_TX_DATA_FILE | od -An -v -tx1 | tr -d ' \n')
rm $DEPLOYMENT_TX_DATA_FILE

# Send transaction to blockchain
echo "Sending contract creation transaction..."
cast send --rpc-url $RPC_URL --private-key $MINTER_PK --create $bytecode > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address
art_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 4p)
art_contract_address_array=($art_contract_address_str)
art_contract_address=${art_contract_address_array[1]}
rm $DEPLOY_CONTRACT_RESULT_FILE

# Send activation transaction
echo "Sending activation transaction..."
if [ -f ACTIVATION_TX_DATA_FILE ]; then
    cast send --rpc-url $RPC_URL --private-key $MINTER_PK 0x0000000000000000000000000000000000000071 "activateProgram(address)" $art_contract_address > /dev/null
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
cargo stylus deploy -e $RPC_URL --private-key $MINTER_PK --dry-run --output-tx-data-to-dir .

# Get contract bytecode
bytecode=$(cat $DEPLOYMENT_TX_DATA_FILE | od -An -v -tx1 | tr -d ' \n')
rm $DEPLOYMENT_TX_DATA_FILE

# Send transaction to blockchain
echo "Sending contract creation transaction..."
cast send --rpc-url $RPC_URL --private-key $MINTER_PK --create $bytecode > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address
nft_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 4p)
nft_contract_address_array=($nft_contract_address_str)
nft_contract_address=${nft_contract_address_array[1]}
rm $DEPLOY_CONTRACT_RESULT_FILE

# Send activation transaction
echo "Sending activation transaction..."
if [ -f ACTIVATION_TX_DATA_FILE ]; then
    cast send --rpc-url $RPC_URL --private-key $MINTER_PK 0x0000000000000000000000000000000000000071 "activateProgram(address)" $nft_contract_address > /dev/null
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
forge create --rpc-url $RPC_URL --private-key $MINTER_PK src/MyToken.sol:MyToken > $DEPLOY_CONTRACT_RESULT_FILE

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
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $nft_contract_address "initialize(address, address)" $art_contract_address $erc20_contract_address

# Wait for 5 seconds
sleep 5s
echo "Contracts initialized"

# ----- #
# Tests #
# ----- #
# Initial check
echo ""
echo "-----------"
echo "Start tests"
echo "-----------"
echo "Initial checks..."
nft_balance_start=$(cast call --rpc-url $RPC_URL $nft_contract_address "balanceOf(address) (uint256)" $USER)
nft_owner_start=$(cast call --rpc-url $RPC_URL $nft_contract_address "ownerOf(uint256) (address)" 0 2>/dev/null)
erc20_balance_start=$(cast call --rpc-url $RPC_URL $erc20_contract_address "balanceOf(address) (uint256)" $USER)
echo "Initial NFT balance: $nft_balance_start"
echo "Initial NFT owner (token id 0): $nft_owner_start"
echo "Initial ERC-20 balance: $erc20_balance_start"
echo ""

# Try to mint NFT (should fail)
echo "Trying to mint NFT (it should fail)..."
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $nft_contract_address "mint()"
echo ""

# Mint ERC-20 tokens
echo "Minting ERC-20 tokens..."
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $erc20_contract_address "mint(uint256)" 20
echo ""

# Mint NFTs
echo "Minting NFTs..."
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $nft_contract_address "mint()"
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $nft_contract_address "mint()"
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $nft_contract_address "mint()"
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $nft_contract_address "mint()"

# Minting check
nft_balance_after_minting=$(cast call --rpc-url $RPC_URL $nft_contract_address "balanceOf(address) (uint256)" $USER)
nft_owner_after_minting=$(cast call --rpc-url $RPC_URL $nft_contract_address "ownerOf(uint256) (address)" 0)
erc20_balance_after_minting=$(cast call --rpc-url $RPC_URL $erc20_contract_address "balanceOf(address) (uint256)" $USER)
echo "NFT balance after minting: $nft_balance_after_minting"
echo "NFT owner after minting (token id 0): $nft_owner_after_minting"
echo "ERC-20 balance after minting: $erc20_balance_after_minting"
echo ""

# Generate art
echo "Generating art..."
nft_art_image=$(cast call --rpc-url $RPC_URL $nft_contract_address "tokenUri(uint256) (string)" 0)
echo "NFT image: $nft_art_image"
echo ""

# Transfering
echo "Transfering NFTs..."
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $nft_contract_address "transferFrom(address,address,uint256)" $USER $RECEIVER 0
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $nft_contract_address "transferFrom(address,address,uint256)" $USER $RECEIVER 1

# Transfering check
balance_minter_after_transfering=$(cast call --rpc-url $RPC_URL $nft_contract_address "balanceOf(address) (uint256)" $USER)
balance_receiver_after_transfering=$(cast call --rpc-url $RPC_URL $nft_contract_address "balanceOf(address) (uint256)" $RECEIVER)
owner_after_transfering=$(cast call --rpc-url $RPC_URL $nft_contract_address "ownerOf(uint256) (address)" 0)
echo "Balance after transfering (minter): $balance_minter_after_transfering"
echo "Balance after transfering (receiver): $balance_receiver_after_transfering"
echo "Owner after transfering (token id 0): $owner_after_transfering"
echo ""

# Generate art (again)
echo "Generating art again..."
nft_art_image_after_transfering=$(cast call --rpc-url $RPC_URL $nft_contract_address "tokenUri(uint256) (string)" 0)
echo "NFT image (after transfering): $nft_art_image_after_transfering"
echo ""

# Generate art directly from the Art contract
echo "Generating art from the Art contract..."
raw_art_image=$(cast call --rpc-url $RPC_URL $art_contract_address "generateArt(uint256,address) (string)" 0 $RECEIVER)
echo "Image (from the Art contract): $raw_art_image"
echo ""

# Mint NFT directly from ERC-20 contract
echo "Minting NFT from the ERC-20 contract..."
cast send --rpc-url $RPC_URL --private-key $MINTER_PK $erc20_contract_address "mintNft()"
balance_after_minting_from_erc20=$(cast call --rpc-url $RPC_URL $nft_contract_address "balanceOf(address) (uint256)" $USER)
echo "Balance after minting from ERC20: $balance_after_minting_from_erc20"
echo ""