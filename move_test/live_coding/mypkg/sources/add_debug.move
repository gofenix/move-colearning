module mypkg::add_debug {
    use std::debug;

    #[test_only]
    const EADDTestError: u64 = 0;

    public fun add(a: u64, b: u64): u64{
        let res = a + b;
        debug::print(&res);
        res
    }

    #[test]
    fun test_add() {
        assert!(add(4, 5) == 9, EADDTestError)
    }
}