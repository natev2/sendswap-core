#!/usr/bin/env -S bash -xe

# Fund the newly created account
aptos account fund-with-faucet --account 0xca666d520b8fec2cf594aaf4cc0f38055ceec2ae96e54e88c305908e063856d7

# Publish the specific module
aptos move publish

# Initialize the Faucet
aptos move run \
    --function-id "0xca666d520b8fec2cf594aaf4cc0f38055ceec2ae96e54e88c305908e063856d7::SEND::initialize_internal" \
    --profile default