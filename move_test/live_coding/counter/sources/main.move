module 0x01::main{
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    struct Counter has key {
        id: UID,
        owner: address,
        value: u64
    }

    public fun owner(counter: &Counter): address{
        counter.owner
    }

    public fun value(counter: &Counter): u64{
        counter.value
    }

    public entry fun create(ctx: &mut TxContext) {
        transfer::share_object(Counter {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            value: 0
        })
    }

    public entry fun increment(counter: &mut Counter) {
        counter.value = counter.value + 1;
    }

    public entry fun set_value(counter: &mut Counter, value: u64, ctx: &TxContext) {
        assert!(counter.owner == tx_context::sender(ctx), 0);
        counter.value = value;
    }

    public entry fun assert_value(counter: &Counter, value: u64) {
        assert!(counter.value == value, 0)
    }

    fun alice() {
        
    }

    fun bob() {

    }

    // 这个是test
    fun foo(a: u64) {
        if(a > 0){
            alice();
        } else {
            bob();
        }
    }
}