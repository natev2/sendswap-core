address swapadmin {

module sendtoken{
    // Uses >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    use aptos_framework::coin;
    use aptos_framework::type_info;
    use std::signer::address_of;
    use std::string;

    // Uses <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Structs >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// SEND Token Marker
    struct SEND has copy, drop, store {}

     /// Container for Send token capabilities
    struct CoinCapabilities<phantom SEND> has key {
        mint_capability: coin::MintCapability<SEND>,
        burn_capability: coin::BurnCapability<SEND>,
        freeze_capability: coin::FreezeCapability<SEND>,
    }

    // Structs <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    // Error codes >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// When caller is not swapadmin
    const E_NOT_SWAPADMIN: u64 = 0;
    /// When coin capabilities have already been initialized
    const E_HAS_CAPABILITIES: u64 = 1;
    /// When coin capabilities have not been initialized
    const E_NO_CAPABILITIES: u64 = 2;

    const ERROR_NOT_GENESIS_ACCOUNT: u64 = 3;

    // Error codes <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Constants >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// precision of SEND token.
    const PRECISION: u8 = 9;

    // Constants <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Public functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// Burn `Send tokens`
    ///
    /// # Assumes
    /// * That since `Send tokens` exist in the first place, that
    ///   `CoinCapabilities` must exist in the swapadmin account
    public fun burn<SEND>(coins: coin::Coin<SEND>) acquires CoinCapabilities {
        // Borrow immutable reference to burn capability
        let burn_capability = &borrow_global<CoinCapabilities<SEND>>(
                @swapadmin).burn_capability;
        coin::burn<SEND>(coins, burn_capability); // Burn coins
    }

    /// Return SEND token address.
    public fun coin_address<SEND>(): address {
        let type_info = type_info::type_of<SEND>();
        type_info::account_address(&type_info)
    }

    public fun assert_genesis_address(account : &signer) {
        assert!(address_of(account) == coin_address<SEND>(), ERROR_NOT_GENESIS_ACCOUNT);
    }

    public fun get_balance(owner: address) {
        coin::balance<SEND>(owner);
    }

    /// Return SEND precision.
    public fun precision(): u8 {
        PRECISION
    }

    // Public functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Public entry functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    #[cmd]
    /// Initialize Send token under swapadmin account
    public entry fun init_send(account: &signer) {
        init_coin<SEND>(
            account,
            string::utf8(b"Send Token"),
            string::utf8(b"SEND"),
            18,
            true,
        );
    }

    #[cmd]
    /// Mint new `amount` of `Send Token`, aborting if not called by
    /// swapadmin account or if `CoinCapabilities` uninitialized
    public entry fun mint<SEND>(account: &signer, amount: u64): coin::Coin<SEND> acquires CoinCapabilities {
        // Get account address
        let account_address = address_of(account);
        // Assert caller is swapadmin
        assert!(account_address == @swapadmin, E_NOT_SWAPADMIN);
        assert!(exists<CoinCapabilities<SEND>>(account_address),
            E_NO_CAPABILITIES); // Assert coin capabilities initialized
        // Borrow immutable reference to mint capability
        let mint_capability = &borrow_global<CoinCapabilities<SEND>>(
                account_address).mint_capability;
        // Mint specified amount
        coin::mint<SEND>(amount, mint_capability)
    }

    // Public entry functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    // Private functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /// Initialize given coin type under swapadmin account
    fun init_coin<SEND>(
        account: &signer,
        name: string::String,
        symbol: string::String,
        decimals: u8,
        monitor_supply: bool,
    ) {
        // Assert caller is swapadmin
        assert!(address_of(account) == @swapadmin, E_NOT_SWAPADMIN);
        // Assert swapadmin does not already have coin capabilities stored
        assert!(!exists<CoinCapabilities<SEND>>(@swapadmin),
            E_HAS_CAPABILITIES);
        // Initialize coin, storing capabilities
        let (
            burn_capability, 
            freeze_capability, 
            mint_capability
        ) = coin::initialize<SEND>(
            account, name, symbol, decimals, monitor_supply);
        // Store capabilities under swapadmin account
        move_to<CoinCapabilities<SEND>>(account,
            CoinCapabilities<SEND>{
                mint_capability, 
                burn_capability, 
                freeze_capability
            });
    }

    // Private functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Tests >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    #[test(swapadmin = @swapadmin)]
    #[expected_failure(abort_code = 1)]
    /// Verify failure for capabilities already registered
    fun test_init_has_caps(
        swapadmin: &signer
    ) {
        init_send(swapadmin); // Initialize coin types
        init_send(swapadmin); // Attempt invalid re-init
    }

    #[test(account = @user)]
    #[expected_failure(abort_code = 0)]
    /// Verify failure for unauthorized caller
    fun test_init_not_swapadmin(
        account: &signer
    ) {
        init_send(account); // Attempt invalid init
    }

    #[test(account = @swapadmin)]
    /// Verify successful mint, then burn
    fun test_mint_and_burn(
        account: &signer
    ) acquires CoinCapabilities {
        init_send(account); // Initialize both send token
        let send_token = mint<SEND>(account, 200); // Mint 200 Send tokens
        // Assert correct value minted
        assert!(coin::value(&send_token) == 200, 0);
        burn<SEND>(send_token); // Burn coins
    }

    #[test(account = @user)]
    #[expected_failure(abort_code = 0)]
    /// Verify failure for unauthorized caller
    fun test_mint_not_swapadmin(
        account: &signer
    ): coin::Coin<SEND>
    acquires CoinCapabilities {
        mint<SEND>(account, 200) // Attempt invalid mint
    }

    #[test(account = @swapadmin)]
    #[expected_failure(abort_code = 2)]
    /// Verify failure for uninitialized capabilities
    fun test_mint_no_capabilities(
        account: &signer
    ): coin::Coin<SEND>
    acquires CoinCapabilities {
        mint<SEND>(account, 200) // Attempt invalid mint
    }

    // Tests <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


}

}