address swapadmin {
/// Helper module to do u64 arith.
module Arith {

    use std::error;

    const ERR_INVALID_CARRY:  u64 = 301;
    const ERR_INVALID_BORROW: u64 = 302;

    const P32: u64 = 0x100000000;
    const P64: u128 = 0x10000000000000000;

     /// split u64 to (high, low)
    public fun split_u64(i: u64): (u64, u64) {
        (i >> 32, i & 0xFFFFFFFF)
    }

    spec split_u64 {
        pragma opaque; // MVP cannot reason about bitwise operation
        ensures result_1 == i / P32;
        ensures result_2 == i % P32;
    }

    /// combine (high, low) to u64,
    /// any lower bits of `high` will be erased, any higher bits of `low` will be erased.
    public fun combine_u64(hi: u64, lo: u64): u64 {
        (hi << 32) | (lo & 0xFFFFFFFF)
    }

    spec combine_u64 {
        pragma opaque; // MVP cannot reason about bitwise operation
        let hi_32 = hi % P32;
        let lo_32 = lo % P32;
        ensures result == hi_32 * P32 + lo_32;
    }

    /// a + b, with carry
    public fun adc(a: u64, b: u64, carry: &mut u64) : u64 {
        assert!(*carry <= 1, error::invalid_argument(ERR_INVALID_CARRY));
        let (a1, a0) = split_u64(a);
        let (b1, b0) = split_u64(b);
        let (c, r0) = split_u64(a0 + b0 + *carry);
        let (c, r1) = split_u64(a1 + b1 + c);
        *carry = c;
        combine_u64(r1, r0)
    }

    spec adc {
        // Carry has either to be 0 or 1
        aborts_if !(carry == 0 || carry == 1);
        ensures carry == 0 || carry == 1;
        // Result with or without carry
        ensures carry == 0 ==> result == a + b + old(carry);
        ensures carry == 1 ==> P64 + result == a + b + old(carry);
    }

    /// a - b, with borrow
    public fun sbb(a: u64, b: u64, borrow: &mut u64): u64 {
        assert!(*borrow <= 1, error::invalid_argument(ERR_INVALID_BORROW));
        let (a1, a0) = split_u64(a);
        let (b1, b0) = split_u64(b);
        let (b, r0) = split_u64(P32 + a0 - b0 - *borrow);
        let borrowed = 1 - b;
        let (b, r1) = split_u64(P32 + a1 - b1 - borrowed);
        *borrow = 1 - b;

        combine_u64(r1, r0)
    }

    spec sbb {
        // Borrow has either to be 0 or 1
        aborts_if !(borrow == 0 || borrow == 1);
        ensures borrow == 0 || borrow == 1;
        // Result with or without borrow
        ensures borrow == 0 ==> result == a - b - old(borrow);
        ensures borrow == 1 ==> result == P64 + a - b - old(borrow);
    }

}
}