module main_package::main_moudle {
    use dep_package::dep_module;

    public fun bar(): u64 {
        dep_module::foo()
    }
}

#[test_only]
module main_package::main_moudleTest{
    use main_package::main_moudle;

    #[test]
    fun bar_test(){
        let result = main_moudle::bar();
        assert!(result == 42, 0);
    }
}