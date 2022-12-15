
module love::chat {

    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
    // use sui::sui::SUI;
    use sui::transfer;
    use sui::event::emit;
    use sui::dynamic_field as df;

    const Item_Type_Photo: vector<u8> = b"photo";
    const Item_Type_Text: vector<u8> = b"text";

    // Resources
    // Asset, contain any thing
    struct MessageAsset has key, store {
        id: UID,
        content: vector<u8>,
        from: address,
        to: address,
        created_at: u64,
    }

    struct MessageItem has store, copy, drop {
        msg_id: ID,
        content: vector<u8>,
        item_type: String,
    }

    struct RedPackItem<phantom CoinType> has store, copy, drop {
        redpack_id: ID,
        value: u64,
    }

    // Events
    struct AssetSentEvent<T: copy + drop> has copy,  drop{
        asset_id: ID,
        content: T,
        from: address,
        to: address,
        created_at: u64,
    }

    public fun new(content: vector<u8>, to: address, ctx: &mut TxContext): MessageAsset {
        let created_at = tx_context::epoch(ctx);
        let from = tx_context::sender(ctx);
        let id = object::new(ctx);
        

        let asset = MessageAsset {
            id,
            content,
            from,
            to,
            created_at,
        };

        asset
    }   

    // Send message 
    public entry fun send(content: vector<u8>, to: address, ctx: &mut TxContext) {
        let asset = new(content, to, ctx);
        let asset_id = object::id(&asset);

        emit(AssetSentEvent {
            asset_id,
            content,
            from: asset.from,
            to,
            created_at: asset.created_at,
        });
        
        transfer::transfer(asset, to);
    }

    public entry fun send_item<Item: store >(content: vector<u8>, to: address, item: Item, ctx: &mut TxContext) {
        
        let asset = new(content, to, ctx);
        let asset_id = object::id(&asset);

        emit(AssetSentEvent {
            asset_id,
            content,
            from: asset.from,
            to,
            created_at: asset.created_at,
        });

        let msg_id = object::id(&asset);
        
        df::add(&mut asset.id, msg_id, item);
        
        transfer::transfer(asset, to);
    }

    fun format_item_type(type: vector<u8>): String {
        let type = if (&type == &Item_Type_Photo) {
            type
        } else {
            Item_Type_Text
        };

        string::utf8(type)
    }

    
}