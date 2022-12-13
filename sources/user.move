
//! registered user in platform
module love::user {
    

    use sui::event::emit;
    use sui::object::{Self, ID, UID};
    use std::option::{Self, Option};
    use std::vector;
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::table::{Self, Table};

    // constants
    const Ilike_Travel: vector<u8> = b"travel";
    const Ilike_Movie: vector<u8> = b"movie";
    const Ilike_Reading: vector<u8> = b"reading";
    const Ilike_Fashion: vector<u8> = b"fashion";
    const Ilike_Tech: vector<u8> = b"tech";
    const Ilike_Migration: vector<u8> = b"migration";

    const Love_Address: address = @love;

    const Gender_Male: vector<u8> = b"male";
    const Gender_Female: vector<u8> = b"female";
    const Gender_Unknown: vector<u8> = b"secrecy";

    // Resources
    struct User has key {
        id: UID,
        nickname: String,
        age: u8,   
        wallet_addr: address,
        avatar: vector<u8>,         // onchain avatar on sui, limit 2m
        avatar_url: Option<String>,    // offchain avatar 
        gender: String,
        language: String,
        city: String,
        country: String,
        ilike: vector<String>,
        bio: String,
        created_at: u64,
    }
    
    struct Friend has store, copy, drop{
        user_id: ID,
        name: String,
        wallet_addr: String,
        avatar: vector<u8>,         // onchain avatar on sui, limit 2m
        avatar_url: Option<String>,    // offchain avatar 
        created_at: u64,
    }

    struct FriendTable has key, store {
        id: UID,
        friends: Table<address, Friend>,
    }

    struct BlacklistTable has key, store {
        id: UID,
        lists: Table<address, u64>,
    }

    struct FriendMangerCap has key, store {
        id: UID,
        owner_addr: address,
    }

    struct BlacklistMangerCap has key, store {
        id: UID,
        owner_addr: address,
    }
    // Platform has a share object: UserGlobalState, contains registered users, block list of users.
    // User will add to the global state when a user registered.
    struct UserGlobalState has key {
        id: UID,
        registers: Table<address, RegisteredUser>,
        blocklists: Table<address, Table<u256, address>>    // 
    }

    struct RegisteredUser has key, store {
        id: UID,
        user_id: ID,
        wallet_addr: address,
        created_at: u64,
    }

    struct UserRegisteredEvent has copy, drop {
        user_id: ID,
        wallet_addr: address,
        created_at: u64,
    }
    
    // Errors
    const EALREADY_EXISTS: u64 = 0;

    fun init(ctx: &mut TxContext) {
        init_global_state(ctx);
    }

    fun init_global_state(ctx: &mut TxContext) { 
        transfer::transfer(FriendTable {
            id: object::new(ctx),
            friends: table::new(ctx),
        }, tx_context::sender(ctx));

        transfer::share_object(UserGlobalState {
            id: object::new(ctx),
            registers: table::new(ctx),
            blocklists: table::new(ctx),
        })
    }

    public fun new_user(
        nickname: vector<u8>, 
        age: u8, 
        avatar: vector<u8>, 
        avatar_url: Option<vector<u8>>, 
        gender: vector<u8>, 
        language: vector<u8>, 
        city: vector<u8>, 
        country: vector<u8>, 
        ilike: vector<vector<u8>>,
        bio: vector<u8>, 
        ctx: &mut TxContext): User {

        let wallet_addr = tx_context::sender(ctx);
        let avatar_url = if (option::is_some(&avatar_url)) { 
            option::some<String>(string::utf8(option::extract(&mut avatar_url))) 
        } else { option::none() };

        let ilikes = vector_string(ilike);

        User {
            id: object::new(ctx),
            nickname: string::utf8(nickname),
            age,
            wallet_addr,
            avatar,
            avatar_url,
            gender: string::utf8(gender),
            language: string::utf8(language),
            city: string::utf8(city),
            country: string::utf8(country),
            ilike: ilikes,
            bio: string::utf8(bio),
            created_at: tx_context::epoch(ctx)
        }
    }


    /// entry fun
    public entry fun create_user(
        state: &mut UserGlobalState,
        nickname: vector<u8>, 
        age: u8, 
        avatar: vector<u8>, 
        avatar_url: Option<vector<u8>>, 
        gender: vector<u8>, 
        language: vector<u8>, 
        city: vector<u8>, 
        country: vector<u8>, 
        ilike: vector<vector<u8>>,
        bio: vector<u8>, 
        ctx: &mut TxContext
    ) {
        let user = new_user(nickname, age, avatar, avatar_url, gender, language, city, country, ilike, bio, ctx);
        let user_id = object::id(&user);
        let wallet_addr = tx_context::sender(ctx);
        let created_at = tx_context::epoch(ctx);

        assert!(!table::contains(&state.registers, wallet_addr), EALREADY_EXISTS);

        // transfer register user to platform 
        transfer::transfer( RegisteredUser {
            id: object::new(ctx),
            user_id ,
            wallet_addr,
            created_at,
        }, Love_Address);

        emit(UserRegisteredEvent { user_id, wallet_addr, created_at });

        // add user to global state registers
        table::add(&mut state.registers, wallet_addr, RegisteredUser {
            id: object::new(ctx),
            user_id,
            wallet_addr,
            created_at,
        });

        // create friends table
        let friend_table = FriendTable {
            id: object::new(ctx),
            friends: table::new(ctx),
        };

        transfer::transfer(friend_table, wallet_addr);
        transfer::transfer(FriendMangerCap { id: object::new(ctx), owner_addr: wallet_addr }, wallet_addr);

        // create a blacklist table
        let blacklist_table = BlacklistTable {
            id: object::new(ctx),
            lists: table::new(ctx), 
        };

        transfer::transfer(blacklist_table, wallet_addr);
        transfer::transfer(BlacklistMangerCap { id: object::new(ctx), owner_addr: wallet_addr }, wallet_addr);

        transfer::transfer(user, tx_context::sender(ctx));

    }

    public entry fun create_user_with_avatar_url(
        state: &mut UserGlobalState,
        nickname: vector<u8>, 
        age: u8, 
        avatar: vector<u8>, 
        avatar_url: vector<u8>, 
        gender: vector<u8>,
        language: vector<u8>, 
        city: vector<u8>, 
        country: vector<u8>, 
        ilike: vector<vector<u8>>,
        bio: vector<u8>, 
        ctx: &mut TxContext
    ) {
        let avatar_url = option::some(avatar_url);
        create_user(state, nickname, age, avatar, avatar_url, gender,language, city, country, ilike, bio, ctx);
    }

    /// entry fun
    public entry fun create_user_without_avatar_url(
        state: &mut UserGlobalState,
        nickname: vector<u8>, 
        age: u8, 
        avatar: vector<u8>, 
        language: vector<u8>, 
        gender: vector<u8>,
        city: vector<u8>, 
        country: vector<u8>, 
        ilike: vector<vector<u8>>,
        bio: vector<u8>, 
        ctx: &mut TxContext
    ) {
        create_user(state, nickname, age, avatar, option::none(), gender, language, city, country, ilike, bio, ctx);
    }

    

    public entry fun update_user_nickname(user: &mut User, new_name: vector<u8>) {
        let nickname = string::utf8(new_name);
        user.nickname = nickname
    }

    public entry fun update_user_avatar(user: &mut User, new_avatar: vector<u8>) {
        user.avatar = new_avatar
    }

    public entry fun update_user_avatar_url(user: &mut User, new_avatar_url: vector<u8>) {
        let avatar_url = string::utf8(new_avatar_url);
        let avatar_u = &mut user.avatar_url;

        option::swap_or_fill(avatar_u, avatar_url);
        // if (option::is_none(avatar_u)) {
        //     option::fill(avatar_u, avatar_url);
        // } else {
        //     option::swap(avatar_u, avatar_url);
        // }
    }

    public entry fun delete_user_avatar_url(user: &mut User) {
        user.avatar_url = option::none();
    }

    public entry fun update_user_age(user: &mut User, new_age: u8) {
        let age = new_age;
        user.age = age;
    }

    public entry fun update_user_language(user: &mut User, new_language: vector<u8>) {
        let language = string::utf8(new_language);
        user.language = language;
    }

    public entry fun update_user_city(user: &mut User, new_city: vector<u8>) {
        let city = string::utf8(new_city);
        user.city = city;
    }

    public entry fun update_user_country(user: &mut User, new_country: vector<u8>) {
        let country = string::utf8(new_country);
        user.country = country;
    }

    public entry fun update_user_ilike(user: &mut User, new_ilike: vector<vector<u8>>,) {
        let ilike = vector_string(new_ilike);
        user.ilike = ilike;
    }

    public entry fun update_user_bio(user: &mut User, new_bio: vector<u8>) {
        let bio = string::utf8(new_bio);
        user.bio = bio;
    }

    public entry fun transfer_user(user: User, to: address) {
        user.wallet_addr = to;
        transfer::transfer(user, to);
    }

    /// Getter 
    public fun nickname(user: &User): String {
        user.nickname
    }

    public fun age(user: &User): u8 {
        user.age
    }

    public fun wallet_addr(user: &User): address {
        user.wallet_addr
    }

    public fun avatar(user: &User): vector<u8> {
        user.avatar
    }

    public fun avatar_url(user: &User): Option<String> {
        user.avatar_url
    }

    public fun language(user: &User): String {
        user.language
    }

    public fun city(user: &User): String {
        user.city
    }

    public fun country(user: &User): String {
        user.country
    }

    public fun ilike(user: &User): vector<String> {
        user.ilike
    }

    public fun bio(user: &User): String {
        user.bio
    }

    public fun created_at(user: &User): u64 {
        user.created_at
    }

    public fun vector_string(vs: vector<vector<u8>>): vector<String> {
        let vss = vector::empty<String>();

        let idx = 0;
        let len = vector::length<vector<u8>>(&vs);
        while (idx < len) {
            vector::reverse(&mut vs);

            vector::push_back(&mut vss, string::utf8(vector::pop_back(&mut vs)));
            idx = idx + 1;
        };

        vss
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        init_global_state(ctx);
    }

}