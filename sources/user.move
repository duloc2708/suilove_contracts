
//! registered user in platform
module love::user {
    
    use sui::object::{Self, UID};
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    const Ilike_Travel: vector<u8> = b"travel";
    const Ilike_Movie: vector<u8> = b"movie";
    const Ilike_Reading: vector<u8> = b"reading";
    const Ilike_Fashion: vector<u8> = b"fashion";
    const Ilike_Tech: vector<u8> = b"tech";
    const Ilike_Migration: vector<u8> = b"migration";

    const Love_Address: address = @love;

    const Gender_Male: vector<u8> = b"male";
    const Gender_Female: vector<u8> = b"female";
    const Gender_Unknown: vector<u8> = b"unknown";

    struct User has key {
        id: UID,
        nickname: String,
        birthday: String,   
        wallet_addr: address,
        avatar: vector<u8>,         // onchain avatar on sui, limit 2m
        avatar_url: Option<String>,    // offchain avatar 
        gender: String,
        language: String,
        city: String,
        country: String,
        ilike: String,
        bio: String,
        created_at: u64,
    }


    public fun new_user(
        nickname: vector<u8>, 
        birthday: vector<u8>, 
        avatar: vector<u8>, 
        avatar_url: Option<vector<u8>>, 
        gender: vector<u8>, 
        language: vector<u8>, 
        city: vector<u8>, 
        country: vector<u8>, 
        ilike: vector<u8>,
        bio: vector<u8>, 
        ctx: &mut TxContext): User {

        let wallet_addr = tx_context::sender(ctx);
        let avatar_url = if (option::is_some(&avatar_url)) { 
            option::some<String>(string::utf8(option::extract(&mut avatar_url))) 
        } else { option::none() };

        User {
            id: object::new(ctx),
            nickname: string::utf8(nickname),
            birthday: string::utf8(birthday),
            wallet_addr,
            avatar,
            avatar_url,
            gender: string::utf8(gender),
            language: string::utf8(language),
            city: string::utf8(city),
            country: string::utf8(country),
            ilike: string::utf8(ilike),
            bio: string::utf8(bio),
            created_at: tx_context::epoch(ctx)
        }
    }


    /// entry fun
    public entry fun create_user(
        nickname: vector<u8>, 
        birthday: vector<u8>, 
        avatar: vector<u8>, 
        avatar_url: Option<vector<u8>>, 
        gender: vector<u8>, 
        language: vector<u8>, 
        city: vector<u8>, 
        country: vector<u8>, 
        ilike: vector<u8>,
        bio: vector<u8>, 
        ctx: &mut TxContext
    ) {
        let user = new_user(nickname, birthday, avatar, avatar_url, gender, language, city, country, ilike, bio, ctx);
        transfer::transfer(user, tx_context::sender(ctx));
    }

    public entry fun create_user_with_avatar_url(
        nickname: vector<u8>, 
        birthday: vector<u8>, 
        avatar: vector<u8>, 
        avatar_url: vector<u8>, 
        gender: vector<u8>,
        language: vector<u8>, 
        city: vector<u8>, 
        country: vector<u8>, 
        ilike: vector<u8>,
        bio: vector<u8>, 
        ctx: &mut TxContext
    ) {
        let avatar_url = option::some(avatar_url);
        create_user(nickname, birthday, avatar, avatar_url, gender,language, city, country, ilike, bio, ctx);
    }

    /// entry fun
    public entry fun create_user_without_avatar_url(
        nickname: vector<u8>, 
        birthday: vector<u8>, 
        avatar: vector<u8>, 
        language: vector<u8>, 
        gender: vector<u8>,
        city: vector<u8>, 
        country: vector<u8>, 
        ilike: vector<u8>,
        bio: vector<u8>, 
        ctx: &mut TxContext
    ) {
        create_user(nickname, birthday, avatar, option::none(), gender, language, city, country, ilike, bio, ctx);
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

    public entry fun update_user_birthday(user: &mut User, new_birthday: vector<u8>) {
        let birthday = string::utf8(new_birthday);
        user.birthday = birthday;
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

    public entry fun update_user_ilike(user: &mut User, new_ilike: vector<u8>) {
        let ilike = string::utf8(new_ilike);
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

    public fun birthday(user: &User): String {
        user.birthday
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

    public fun ilike(user: &User): String {
        user.ilike
    }

    public fun bio(user: &User): String {
        user.bio
    }

    public fun created_at(user: &User): u64 {
        user.created_at
    }

}