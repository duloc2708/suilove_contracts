
//! registered user in platform
module love::user {
    
    use sui::object::{UID};
    use std::option::{Option};
    use std::string::{String};

    struct User has key {
        id: UID,
        nickname: String,
        age: u8,
        avatar: vector<u8>,
        avatar_url: Option<String>,
        language: String,
        city: String,
        country: String,
        bio: String,
        created_at: u64,
    }
}