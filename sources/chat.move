
module love::chat {

    use sui::object::{UID};
    // use std::option::{Self, Option};
    use std::string::{String};
    // use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
    // use sui::sui::SUI;
    // use sui::transfer;

    struct Message has key, store {
        id: UID,
        msg: String,
        from: address,
        to: address,
        created_at: u64,
    }

    
}