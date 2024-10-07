# Stylus workshop (Rust & Solidity)

This repo contains an example of 3 contracts (an ERC-721 contract and an Art contract both written in Rust, and an ERC-20 contract written in Solidity) interacting with each other.

The ERC-721 contract contains a basic Rust implementation of the standard, which calls the external Art contract to generate the image when invoking the `tokenURI` method.

The Art contract contains a Rust implementation of a basic generative art algorithm that draws an image with different colors depending on the address and the token id being passed as inputs. It is based on the [Stylus workshop NFT](https://github.com/OffchainLabs/stylus-workshop-nft/) implementation.

The ERC-20 contract contains a basic Solidity implementation of the standard. It is based on OpenZeppelin's implementation.

## Interactions between contracts

The three contracts interact with each other in the following way:
- On ERC-721 initialization, both Art and ERC-20 contracts are also initialize by invoking the respective `initialize` methods. 
- When the `tokenURI()` method of the ERC-721 contract is invoked, this contract calls method `generate_art` of the Art contract, passing both a `tokenId` and the `owner` of that token.
- When the `generate_art` method of the Art contract is invoked with only a `tokenId` as input, the Art contract calls method `ownerOf` of the ERC-721 contract to obtain the owner of such token.
- When a user tries to mint an NFT the owner must have a minimum balance of ERC-20 tokens. Thus, the `mint` method also invokes the `balanceOf` method of the ERC-20 contract for the minter.
- A user can also try to mint an NFT from the ERC-20 contract, by invoking the method `mintNft()`. This method will call method `mint` of the NFT contract.

## Getting started

Follow the instructions in the [Stylus quickstart](https://docs.arbitrum.io/stylus/stylus-quickstart) to configure your development environment.

You'll also need [Foundry](https://github.com/foundry-rs/foundry) to build and deploy the ERC-20 contract.

## Project structure

Clone the project

```sh
git clone https://github.com/OffchainLabs/stylus-workshop-rust-solidity.git
cd stylus-workshop-rust-solidity
```

There are four directories inside:

- **nft**: contains the Stylus project for the ERC-721 contract
- **art**: contains the Stylus project for the Art contract
- **erc20**: contains the Foundry project for the ERC-20 contract 

## Deploy your contracts

Rust and Solidity contracts are built and deployed differently.

### Rust contracts

For Rust projects, access the project folder and build and deploy the contract using the `cargo stylus` tool. Following is an example for the Art contract.

Access the `art` folder

```sh
cd art
```

Run the check tool

```sh
cargo stylus check
```

Deploy the contract

```sh
cargo stylus deploy -e $YOUR_RPC_URL --private-key $YOUR_PRIVATE_KEY
```

Note that it's generally better to use `--private-key-path` for security reasons.

See `cargo stylus deploy --help` for more information.

### Solidity contract

Access the `erc20` folder

```sh
cd erc20
```

Build the project

```sh
forge build
```

Deploy it

```sh
forge create --rpc-url $YOUR_RPC_URL --private-key $YOUR_PRIVATE_KEY src/MyToken.sol:MyToken
```

See `forge create --help` for more information.

## Test script

You can use the following flow for the most important actions:

1. Create a copy (`.env`) and update the environment variables on [./scripts/.env.example](./scripts/.env.example)
2. [./scripts/1-deploy.sh](./scripts/1-deploy.sh) to deploy all contracts
3. Export all contract addresses in environment variables: ART_CONTRACT_ADDRESS, NFT_CONTRACT_ADDRESS, ERC20_CONTRACT_ADDRESS
4. [./scripts/2-initialize.sh](./scripts/2-initialize.sh) to initialize the contracts
5. [./scripts/mintTokens.sh](./scripts/mintTokens.sh) to mint some ERC-20 tokens
6. [./scripts/mintNft.sh](./scripts/mintNft.sh) to mint an NFT
7. [./scripts/getBalance.sh](./scripts/getBalance.sh) to obtain the balance of the minter
8. [./scripts/getTokenImage.sh](./scripts/getTokenImage.sh) to get the image generated for tokenId 0
9. [./scripts/transferNft.sh](./scripts/transferNft.sh) to transfer the NFT 0 from the minter to the RECEIVER
10. [./scripts/mintNftFromTokenContract.sh](./scripts/mintNftFromTokenContract.sh) to mint an NFT from the ERC-20 contract

## How to run a local dev node

Instructions to setup a local dev node can be found [here](https://docs.arbitrum.io/run-arbitrum-node/run-local-dev-node).

## Useful resources

- [Stylus quickstart](https://docs.arbitrum.io/stylus/stylus-quickstart)
- [Stylus by example](https://stylus-by-example.org/)
- [Awesome Stylus](https://github.com/OffchainLabs/awesome-stylus)
- [Counter contract](https://github.com/OffchainLabs/stylus-workshop-counter)
- [Interactions between Rust and Solidity](https://github.com/OffchainLabs/stylus-workshop-rust-solidity/)
- [Presentation slides](https://docs.google.com/presentation/d/e/2PACX-1vQB44hpWHBig5REVntjxK-Djs8p1XuQB26pg0ouldTWxTaaYpK3awEV4A8Spv9Z3nCr-473ix853sbr/pub?start=false&loop=false&delayms=3000)
- [Telegram group](https://t.me/arbitrum_stylus)
- [Discord channel](https://discord.com/channels/585084330037084172/1146789176939909251)

## Stylus reference links

- [Stylus documentation](https://docs.arbitrum.io/stylus/stylus-gentle-introduction)
- [Stylus SDK](https://github.com/OffchainLabs/stylus-sdk-rs)
- [Cargo Stylus](https://github.com/OffchainLabs/cargo-stylus)

## Disclaimer

This code has **not** been audited and should **not** be used in a production environment.
