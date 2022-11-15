
//! registered user in platform
module love::user {
    
    use sui::object::{Self, UID};
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    const Hobby_Travel: vector<u8> = b"travel";
    const Hobby_Movie: vector<u8> = b"movie";
    const Hobby_Reading: vector<u8> = b"reading";
    const Hobby_Fashion: vector<u8> = b"fashion";
    const Hobby_Tech: vector<u8> = b"tech";
    const Hobby_Migration: vector<u8> = b"migration";

    struct User has key {
        id: UID,
        nickname: String,
        birthday: String,   // only month and day, e.g. 4-8 or 4/8
        age_group: String,
        wallet_addr: address,
        avatar: vector<u8>,         // onchain avatar on sui, limit 2m
        avatar_url: Option<String>,    // offchain avatar 
        language: String,
        city: String,
        country: String,
        hobby: String,
        bio: String,
        created_at: u64,
    }


    public fun new_user(
        nickname: vector<u8>, 
        birthday: vector<u8>, 
        age_group: vector<u8>,
        avatar: vector<u8>, 
        avatar_url: Option<vector<u8>>, 
        language: vector<u8>, 
        city: vector<u8>, 
        country: vector<u8>, 
        hobby: vector<u8>,
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
            age_group: string::utf8(age_group),
            wallet_addr,
            avatar,
            avatar_url,
            language: string::utf8(language),
            city: string::utf8(city),
            country: string::utf8(country),
            hobby: string::utf8(hobby),
            bio: string::utf8(bio),
            created_at: tx_context::epoch(ctx)
        }
    }

    /// entry fun
    public entry fun create_user(
        nickname: vector<u8>, 
        birthday: vector<u8>, 
        age_group: vector<u8>,
        avatar: vector<u8>, 
        avatar_url: Option<vector<u8>>, 
        language: vector<u8>, 
        city: vector<u8>, 
        country: vector<u8>, 
        hobby: vector<u8>,
        bio: vector<u8>, 
        ctx: &mut TxContext
    ) {
        let user = new_user(nickname, birthday, age_group, avatar, avatar_url, language, city, country, hobby, bio, ctx);
        transfer::transfer(user, tx_context::sender(ctx));
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

    public entry fun update_user_hobby(user: &mut User, new_hobby: vector<u8>) {
        let hobby = string::utf8(new_hobby);
        user.hobby = hobby;
    }

    public entry fun update_user_bio(user: &mut User, new_bio: vector<u8>) {
        let bio = string::utf8(new_bio);
        user.bio = bio;
    }

    public entry fun update_user_age_group(user: &mut User, new_age_group: vector<u8>) {
        let age_group = string::utf8(new_age_group);
        user.age_group = age_group;
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

    public fun age_group(user: &User): String {
        user.age_group
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

    public fun hobby(user: &User): String {
        user.hobby
    }

    public fun bio(user: &User): String {
        user.bio
    }

    public fun created_at(user: &User): u64 {
        user.created_at
    }

}