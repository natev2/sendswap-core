#!/usr/bin/env -S bash -xe

# Fund the newly created account
# aptos account fund-with-faucet --account 0xf649a210b9f3c014eb25ec84014eb64e04264c8309325dc38bc5cfd44172a8e9

# Publish the specific module
# aptos move publish --profile swapadmin

# Initialize SEND Token as a Coin on Aptos
aptos move run \
    --function-id "0xf649a210b9f3c014eb25ec84014eb64e04264c8309325dc38bc5cfd44172a8e9::sendtoken::init_send" \
    --profile swapadmin