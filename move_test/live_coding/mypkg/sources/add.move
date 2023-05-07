module mypkg::add {
    #[test_only]
    const EADDTestError: u64 = 0;

    public fun add(a: u64, b: u64): u64{
        a + b
    }

    #[test]
    fun test_add() {
        assert!(add(4, 5) == 9, EADDTestError)
    }
}