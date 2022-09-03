address SwapAdmin {

module SEND {
    use Std::ASCII::string;
    use AptosFramework::Coin::Self;
    use Std::Signer;
    use AptosFramework::TypeInfo;

    // Errors
    /// When capability is missed on account.
    const ERR_CAP_MISSED: u64 = 100;

    /// When capability already exists on account.
    const ERR_CAP_EXISTS: u64 = 101;

    const ERROR_NOT_GENESIS_ACCOUNT: u64 = 10001;

    /// precision of SEND token.
    const PRECISION: u8 = 9;

    /// SEND token marker.
    struct SEND has copy, drop, store {}

    /// The struct to store capability: mint and burn.
    struct Capability<CapType: store> has key {
        cap: CapType
    }

    /// Initializing `SEND` as coin in Aptos network.
    public fun initialize_internal(account: &signer) {
        // Initialize `SEND` as coin type using Aptos Framework.
        let (mint_cap, burn_cap) = Coin::initialize<SEND>(
            account,
            string(b"Send Token"),
            string(b"SEND"),
            10,
            true,
        );

        // Store mint and burn capabilities under user account.
        move_to(account, Capability { cap: mint_cap });
        move_to(account, Capability { cap: burn_cap });
    }


    /// Extract mint or burn capability from user account.
    /// Returns extracted capability.
    public fun extract_capability<CapType: store>(account: &signer): CapType acquires Capability {
        let account_addr = Signer::address_of(account);

        // Check if capability stored under account.
        assert!(exists<Capability<CapType>>(account_addr), ERR_CAP_MISSED);

        // Get capability stored under account.
        let Capability { cap } =  move_from<Capability<CapType>>(account_addr);
        cap
    }

    /// Put mint or burn `capability` under user account.
    public fun put_capability<CapType: store>(account: &signer, capability: CapType) {
        let account_addr = Signer::address_of(account);

        // Check if capability doesn't exist under account so we can store.
        assert!(!exists<Capability<CapType>>(account_addr), ERR_CAP_EXISTS);

        // Store capability.
        move_to(account, Capability<CapType> {
            cap: capability
        });
    }

    public fun mint(amount: u64, _cap: &Coin::MintCapability<SEND>, account: signer) {
        let coin = Coin::mint<SEND>(amount, _cap);
        let account = Signer::address_of(&account);
        Coin::deposit<SEND>(account, coin);
    }

    /// Return SEND token address.
    public fun coin_address<SEND>(): address {
        let type_info = TypeInfo::type_of<SEND>();
        TypeInfo::account_address(&type_info)
    }

    public fun assert_genesis_address(account : &signer) {
        assert!(Signer::address_of(account) == coin_address<SEND>(), ERROR_NOT_GENESIS_ACCOUNT);
    }


    public fun get_balance(owner: address) {
        Coin::balance<SEND>(owner);
    }

    /// Return SEND precision.
    public fun precision(): u8 {
        PRECISION
    }

}
}