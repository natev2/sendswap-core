#!/usr/bin/env -S bash -xe

# Fund the newly created account
# aptos account fund-with-faucet --account 0xf649a210b9f3c014eb25ec84014eb64e04264c8309325dc38bc5cfd44172a8e9


# Mint some Send Tokens to an account with Mint Capability
aptos move run \
    --function-id "swapadmin::sendtoken::mint" \
    --args string:mint_capability u64:20 \
    --profile swapadmin