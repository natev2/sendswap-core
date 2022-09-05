address swapadmin {

module TimelyReleasePool {
    use std::signer;
    use std::error;
    use aptos_framework::coin;
    // use aptos_framework::timestamp;
    // use aptos_framework::account;

    const ERROR_LINEAR_RELEASE_EXISTS: u64 = 0;
    const ERROR_LINEAR_NOT_READY_YET: u64 = 1;
    const ERROR_EVENT_INIT_REPEATE: u64 = 2;
    const ERROR_EVENT_NOT_START_YET: u64 = 3;
    const ERROR_TRESURY_IS_EMPTY: u64 = 4;

    struct TimelyReleasePool<phantom PoolT, phantom CoinT> has key {
        // Total treasury amount
        total_treasury_amount: u64,
        // treasury total amount
        treasury: coin::Coin<CoinT>,
        // Release amount per time
        release_per_time: u64,
        // Begin of release time
        begin_time: u64,
        // latest withdraw time
        latest_withdraw_time: u64,
        // latest release time
        latest_release_time: u64,
        // How long the user can withdraw in each period, 0 is every seconds
        interval: u64,
        // Signer Capability
    }

    struct WithdrawCapability<phantom PoolT, phantom CoinT> has key, store {}

    public fun init<PoolT: store, CoinT: store>(
        sender: &signer,
        init_coin: coin::Coin<CoinT>,
        begin_time: u64,
        interval: u64,
        release_per_time: u64
        ): WithdrawCapability<PoolT, CoinT> {
            let sender_addr = signer::address_of(sender);
            assert!(!exists<TimelyReleasePool<PoolT, CoinT>>(sender_addr), error::invalid_state(ERROR_LINEAR_RELEASE_EXISTS));

            let total_treasury_amount = coin::value<CoinT>(&init_coin);
            move_to(sender, TimelyReleasePool<PoolT, CoinT> {
            treasury: init_coin,
            total_treasury_amount,
            release_per_time,
            begin_time,
            latest_withdraw_time: begin_time,
            latest_release_time: begin_time,
            interval,
        });

        WithdrawCapability<PoolT, CoinT> {}
    }

    /// Uninitialize a timely pool
    public fun uninit<PoolT: store, CoinT: store>(cap: WithdrawCapability<PoolT, CoinT>, broker: address)
    : coin::Coin<CoinT> acquires TimelyReleasePool {
        let WithdrawCapability<PoolT, CoinT> {} = cap;
        let TimelyReleasePool<PoolT, CoinT> {
            total_treasury_amount: _,
            treasury,
            release_per_time: _,
            begin_time: _,
            latest_withdraw_time: _,
            latest_release_time: _,
            interval: _,
        } = move_from<TimelyReleasePool<PoolT, CoinT>>(broker);

        treasury
    }

}
}