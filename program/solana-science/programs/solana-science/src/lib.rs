use std::str::FromStr;

use anchor_lang::prelude::*;
use anchor_lang::solana_program::clock::Clock;

use anchor_lang::system_program::transfer;

use anchor_lang::system_program::{self, Transfer};
use anchor_spl::{
    associated_token::AssociatedToken,
    token_2022::Token2022,
    token_2022_extensions::token_metadata::{
        token_metadata_initialize, token_metadata_update_field, TokenMetadataInitialize,
        TokenMetadataUpdateField,
    },
    token_interface::{
        burn, initialize_mint2, metadata_pointer_initialize, mint_to, set_authority,
        spl_token_metadata_interface::borsh::BorshDeserialize, transfer_checked, Burn,
        InitializeMint2, MetadataPointerInitialize, Mint, MintTo, SetAuthority, TokenAccount,
        TransferChecked,
    },
};
use anchor_spl::{
    token_2022::spl_token_2022::instruction::AuthorityType,
    token_interface::spl_token_metadata_interface::state::Field,
};

declare_id!("Bp7LbjQdrAGGQft9TyJYiGvmKP6NzHZvvD35wiW12FMQ");

const AUTHORITY_SEED: &[u8] = b"SOLANA_SCIENCE_AUTHORITY_SEED";
const GAME_ACCOUNT_SEED: &[u8] = b"SOLANA_SCIENCE_GAME_ACCOUNT";

const EXP_PER_TIME_UNIT: f64 = 0.01;
const TIME_TO_READ_BOOK: i64 = 120;
const BID_INCREASE: u64 = 100;

const BOOK_SCORE_LEVEL_1: u64 = 10;
const BOOK_SCORE_LEVEL_2: u64 = 100;

const LAST_MODIFIED_FIELD: &str = "Last Modified";
const CURRENT_BOOK_FIELD: &str = "Current Book";
const BOOKS_READ_FIELD: &str = "Book Score";
const EXPERIENCE_FIELD: &str = "Experience";
const PUBLISHED_DECENT_BOOKS: &str = "Published Decent Books";
const PUBLISHED_INTERESING_BOOKS: &str = "Published Interesting Books";
const PUBLISHED_FASCINATING_BOOKS: &str = "Published Fascinating Books";
const CASH_FIELD: &str = "Cash";

struct CustomData {
    pub cash: u64,
    pub next_timestamp: i64,
    pub current_book: Pubkey,
    pub book_score: u64,
    pub experience: f64,
    //pub published_useless_books: u64,
    //pub published_mediocre_books: u64,
    pub published_decent_books: u64,
    pub published_interesting_books: u64,
    //pub published_captivating_books: u64,
    pub published_fascinating_books: u64,
    //pub published_mind_blowing_books: u64,
    //pub published_epic_books: u64,
}

fn init_mint<'info>(
    ctx: &Context<NewGame<'info>>,
    mint_acc: AccountInfo<'info>,
    name: &str,
    symbol: &str,
    uri: &str,
) -> Result<()> {
    let bump = ctx.bumps.scientist_authority;
    let signer_seeds: &[&[&[u8]]] = &[&[AUTHORITY_SEED, &[bump]]];

    metadata_pointer_initialize(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            MetadataPointerInitialize {
                token_program_id: ctx.accounts.token_program.to_account_info(),
                mint: mint_acc.clone(),
            },
        ),
        Some(ctx.accounts.scientist_authority.key()),
        Some(mint_acc.key()),
    )?;

    initialize_mint2(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            InitializeMint2 {
                mint: mint_acc.clone(),
            },
        ),
        0,
        &ctx.accounts.scientist_authority.key(),
        Some(&ctx.accounts.scientist_authority.key()),
    )?;

    transfer(
        CpiContext::new(
            ctx.accounts.system_program.to_account_info(),
            Transfer {
                from: ctx.accounts.payer.to_account_info(),
                to: mint_acc.clone(),
            },
        ),
        1000000000,
    )?;

    token_metadata_initialize(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            TokenMetadataInitialize {
                token_program_id: ctx.accounts.token_program.to_account_info(),
                metadata: mint_acc.clone(),
                update_authority: ctx.accounts.scientist_authority.to_account_info(),
                mint: mint_acc.clone(),
                mint_authority: ctx.accounts.scientist_authority.to_account_info(),
            },
        )
        .with_signer(signer_seeds),
        name.to_string(),
        symbol.to_string(),
        uri.to_string(),
    )?;
    Ok(())
}

fn get_custom_data<'info>(scientist_mint: AccountInfo<'info>) -> CustomData {
    const TIME_OFFSET: usize = 344;
    let data = &scientist_mint.data.borrow()[TIME_OFFSET..];
    let mut i = 0;
    let mut strings = Vec::new();
    while i < data.len() {
        let key_size = u32::from_le_bytes(data[i..(i + 4)].try_into().unwrap()) as usize;
        msg!("key_size: {}", key_size);
        i += 4 + key_size;
        let value_size = u32::from_le_bytes(data[i..(i + 4)].try_into().unwrap()) as usize;
        i += 4;
        let value_string = String::from_utf8(data[i..(i + value_size)].to_vec()).unwrap();
        msg!("value string: {}", value_string);
        i += value_size;

        strings.push(value_string);
    }

    CustomData {
        cash: strings[0].parse::<u64>().unwrap(),
        next_timestamp: strings[1].parse::<i64>().unwrap(),
        current_book: Pubkey::from_str(strings[2].as_str()).unwrap(),
        book_score: strings[3].parse::<u64>().unwrap(),
        experience: strings[4].parse::<f64>().unwrap(),
        published_decent_books: strings[5].parse::<u64>().unwrap(),
        published_interesting_books: strings[6].parse::<u64>().unwrap(),
        published_fascinating_books: strings[7].parse::<u64>().unwrap(),
    }
}

fn get_research_time<'info>(scientist_mint: AccountInfo<'info>) -> i64 {
    let custom_data = get_custom_data(scientist_mint);
    let clock = Clock::get().unwrap();
    let unix_timestamp = clock.unix_timestamp;
    unix_timestamp - custom_data.next_timestamp
}

#[program]
pub mod solana_science {

    use std::borrow::BorrowMut;

    use super::*;

    #[error_code]
    pub enum ScienceError {
        #[msg("Scientist is busy")]
        BusyScientist,
        #[msg("Another bidder was quicker, try again")]
        OutdatedBid,
    }

    pub fn new_game(ctx: Context<NewGame>) -> Result<()> {
        init_mint(
            &ctx,
            ctx.accounts.decent_book_mint.to_account_info(),
            "Decent Book",
            "SSDB",
            "http://solanascience.com/SSDB",
        )?;
        init_mint(
            &ctx,
            ctx.accounts.interesting_book_mint.to_account_info(),
            "Interesting Book",
            "ISDB",
            "http://solanascience.com/ISDB",
        )?;
        init_mint(
            &ctx,
            ctx.accounts.fascinating_book_mint.to_account_info(),
            "Fascinating Book",
            "FSDB",
            "http://solanascience.com/FSDB",
        )?;
        Ok(())
    }

    pub fn new_scientist(ctx: Context<NewScientist>) -> Result<()> {
        let bump = ctx.bumps.scientist_authority;
        let signer_seeds: &[&[&[u8]]] = &[&[AUTHORITY_SEED, &[bump]]];

        msg!("{}", ctx.accounts.scientist_mint.key().to_string());

        metadata_pointer_initialize(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                MetadataPointerInitialize {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    mint: ctx.accounts.scientist_mint.to_account_info(),
                },
            ),
            Some(ctx.accounts.scientist_authority.key()),
            Some(ctx.accounts.scientist_mint.key()),
        )?;

        initialize_mint2(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                InitializeMint2 {
                    mint: ctx.accounts.scientist_mint.to_account_info(),
                },
            ),
            0,
            &ctx.accounts.scientist_authority.key(),
            Some(&ctx.accounts.scientist_authority.key()),
        )?;

        transfer(
            CpiContext::new(
                ctx.accounts.system_program.to_account_info(),
                Transfer {
                    from: ctx.accounts.payer.to_account_info(),
                    to: ctx.accounts.scientist_mint.to_account_info(),
                },
            ),
            1000000000,
        )?;

        token_metadata_initialize(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataInitialize {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                    mint: ctx.accounts.scientist_mint.to_account_info(),
                    mint_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            "name1".to_string(),
            "symbol1".to_string(),
            "http://uri1.se".to_string(),
        )?;

        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(CASH_FIELD.to_string()),
            1000.to_string(),
        )?;

        Ok(())
    }

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let bump = ctx.bumps.scientist_authority;
        let signer_seeds: &[&[&[u8]]] = &[&[AUTHORITY_SEED, &[bump]]];
        mint_to(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                MintTo {
                    mint: ctx.accounts.scientist_mint.to_account_info(),
                    to: ctx.accounts.scientist_account.to_account_info(),
                    authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            1,
        )?;

        set_authority(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                SetAuthority {
                    account_or_mint: ctx.accounts.scientist_mint.to_account_info(),
                    current_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            AuthorityType::MintTokens,
            None,
        )?;

        let clock = Clock::get()?;
        let unix_timestamp = clock.unix_timestamp;

        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(LAST_MODIFIED_FIELD.to_string()),
            unix_timestamp.to_string(),
        )?;

        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(CURRENT_BOOK_FIELD.to_string()),
            Pubkey::new_from_array([0; 32]).to_string(),
        )?;
        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(BOOKS_READ_FIELD.to_string()),
            0.to_string(),
        )?;
        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(EXPERIENCE_FIELD.to_string()),
            (0.0).to_string(),
        )?;
        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(PUBLISHED_DECENT_BOOKS.to_string()),
            0.to_string(),
        )?;
        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(PUBLISHED_INTERESING_BOOKS.to_string()),
            0.to_string(),
        )?;
        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(PUBLISHED_FASCINATING_BOOKS.to_string()),
            0.to_string(),
        )?;

        Ok(())
    }

    pub fn research(ctx: Context<Research>, book_type: u8) -> Result<()> {
        let research_time = get_research_time(ctx.accounts.scientist_mint.to_account_info());
        let custom_data = get_custom_data(ctx.accounts.scientist_mint.to_account_info());

        if research_time < 0 {
            return err!(ScienceError::BusyScientist);
        }

        msg!("byte is {}", book_type);
        msg!("{}", ctx.accounts.decent_book_account.key().to_string());
        let bump = ctx.bumps.scientist_authority;
        let signer_seeds: &[&[&[u8]]] = &[&[AUTHORITY_SEED, &[bump]]];

        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(EXPERIENCE_FIELD.to_string()),
            (custom_data.experience + EXP_PER_TIME_UNIT * research_time as f64).to_string(),
        )?;

        match book_type {
            1 => {
                burn(
                    CpiContext::new(
                        ctx.accounts.token_program.to_account_info(),
                        Burn {
                            mint: ctx.accounts.decent_book_mint.to_account_info(),
                            from: ctx.accounts.decent_book_account.to_account_info(),
                            authority: ctx.accounts.owner.to_account_info(),
                        },
                    ),
                    1,
                )?;
            }
            2 => {
                burn(
                    CpiContext::new(
                        ctx.accounts.token_program.to_account_info(),
                        Burn {
                            mint: ctx.accounts.interesting_book_mint.to_account_info(),
                            from: ctx.accounts.interesting_book_account.to_account_info(),
                            authority: ctx.accounts.owner.to_account_info(),
                        },
                    )
                    .with_signer(signer_seeds),
                    1,
                )?;
            }
            3 => {
                burn(
                    CpiContext::new(
                        ctx.accounts.token_program.to_account_info(),
                        Burn {
                            mint: ctx.accounts.fascinating_book_mint.to_account_info(),
                            from: ctx.accounts.fascinating_book_account.to_account_info(),
                            authority: ctx.accounts.owner.to_account_info(),
                        },
                    )
                    .with_signer(signer_seeds),
                    1,
                )?;
            }
            _ => panic!(),
        }

        let current_book_key = match book_type {
            0 => ctx.accounts.decent_book_mint.key(),
            1 => ctx.accounts.interesting_book_mint.key(),
            2 => ctx.accounts.fascinating_book_mint.key(),
            _ => panic!(),
        };

        let clock = Clock::get().unwrap();
        let unix_timestamp = clock.unix_timestamp;

        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(CURRENT_BOOK_FIELD.to_string()),
            current_book_key.to_string(),
        )?;

        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(LAST_MODIFIED_FIELD.to_string()),
            (unix_timestamp + TIME_TO_READ_BOOK).to_string(),
        )?;

        Ok(())
    }

    pub fn publish_book(ctx: Context<PublishBook>) -> Result<()> {

        let research_time = get_research_time(ctx.accounts.scientist_mint.to_account_info());
        let custom_data = get_custom_data(ctx.accounts.scientist_mint.to_account_info());

        if research_time < 0 {
            return err!(ScienceError::BusyScientist);
        }

        // TODO: Check for ideas first.

        const LOWER: u64 = BOOK_SCORE_LEVEL_1 + 1;
        let (book_mint, token_acc) = match custom_data.book_score {
            0..=BOOK_SCORE_LEVEL_1 => (
                ctx.accounts.decent_book_mint.key(),
                ctx.accounts.decent_book_account.key(),
            ),
            LOWER..=BOOK_SCORE_LEVEL_2 => (
                ctx.accounts.interesting_book_mint.key(),
                ctx.accounts.interesting_book_account.key(),
            ),
            _ => (
                ctx.accounts.fascinating_book_mint.key(),
                ctx.accounts.fascinating_book_account.key(),
            ),
        };

        let payout_book_mint;
        if ctx.accounts.game_account.sale_book == ctx.accounts.decent_book_mint.key(){
            payout_book_mint = ctx.accounts.decent_book_mint.to_account_info();
        }
        else if ctx.accounts.game_account.sale_book == ctx.accounts.interesting_book_mint.key(){
            payout_book_mint = ctx.accounts.interesting_book_mint.to_account_info();
        }
        else if ctx.accounts.game_account.sale_book == ctx.accounts.fascinating_book_mint.key(){
            payout_book_mint = ctx.accounts.fascinating_book_mint.to_account_info();
        }
        else{
            ctx.accounts.game_account.sale_book = book_mint;
            ctx.accounts.game_account.seller = token_acc;
            ctx.accounts.game_account.seller_scientist = ctx.accounts.scientist_mint.key();
            ctx.accounts.game_account.highest_bid = 200;

            return Ok(());
        }

        let bump = ctx.bumps.scientist_authority;
        let signer_seeds: &[&[&[u8]]] = &[&[AUTHORITY_SEED, &[bump]]];

        if ctx.accounts.game_account.highest_bid > 200{
            mint_to(CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                MintTo{
                    mint: payout_book_mint,
                    to: ctx.accounts.highest_bidder.to_account_info(),
                    authority: ctx.accounts.scientist_authority.to_account_info(),
                }
            ).with_signer(signer_seeds), 1)?;
        }

        let seller_custom_data = get_custom_data(ctx.accounts.previous_seller_scientist.to_account_info());

        // MINT SCIENCE TOKENS HERE
        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.previous_seller_scientist.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(CASH_FIELD.to_string()),
            (seller_custom_data.cash + ctx.accounts.game_account.highest_bid).to_string(),
        )?;

        ctx.accounts.game_account.sale_book = book_mint;
        ctx.accounts.game_account.seller = token_acc;
        ctx.accounts.game_account.seller_scientist = ctx.accounts.scientist_mint.key();
        ctx.accounts.game_account.highest_bid = 200;

        Ok(())
    }

    pub fn place_bid(ctx: Context<PlaceBid>, bid: u64) -> Result<()> {
        if ctx.accounts.game_account.highest_bid != (bid - BID_INCREASE){
            return err!(ScienceError::OutdatedBid);
        }

        let book_token_acc;
        if ctx.accounts.game_account.sale_book == ctx.accounts.decent_book_mint.key(){
            book_token_acc = ctx.accounts.decent_book_account.key();
        }
        else if ctx.accounts.game_account.sale_book == ctx.accounts.interesting_book_mint.key(){
            book_token_acc = ctx.accounts.interesting_book_account.key();
        }
        else if ctx.accounts.game_account.sale_book == ctx.accounts.fascinating_book_mint.key(){
            book_token_acc = ctx.accounts.fascinating_book_account.key();
        }
        else{
            return err!(ScienceError::OutdatedBid);
        }

        let bump = ctx.bumps.scientist_authority;
        let signer_seeds: &[&[&[u8]]] = &[&[AUTHORITY_SEED, &[bump]]];

        if ctx.accounts.game_account.highest_bid > 200 {
            let previous_bidder_custom_data = get_custom_data(ctx.accounts.previous_bidder.to_account_info());

            token_metadata_update_field(
                CpiContext::new(
                    ctx.accounts.token_program.to_account_info(),
                    TokenMetadataUpdateField {
                        token_program_id: ctx.accounts.token_program.to_account_info(),
                        metadata: ctx.accounts.previous_bidder.to_account_info(),
                        update_authority: ctx.accounts.scientist_authority.to_account_info(),
                    },
                )
                .with_signer(signer_seeds),
                Field::Key(CASH_FIELD.to_string()),
                (previous_bidder_custom_data.cash + ctx.accounts.game_account.highest_bid).to_string(),
            )?;
        }

        ctx.accounts.game_account.highest_bidder = book_token_acc;
        ctx.accounts.game_account.highest_bidder_scientist = ctx.accounts.scientist_mint.key();
        ctx.accounts.game_account.highest_bid += BID_INCREASE;

        let custom_data = get_custom_data(ctx.accounts.scientist_mint.to_account_info());

        if custom_data.cash < ctx.accounts.game_account.highest_bid{
            return err!(ScienceError::OutdatedBid);
        }

        token_metadata_update_field(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataUpdateField {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                },
            )
            .with_signer(signer_seeds),
            Field::Key(CASH_FIELD.to_string()),
            (custom_data.cash - ctx.accounts.game_account.highest_bid).to_string(),
        )?;

        Ok(())
    }
}

#[derive(Accounts)]
pub struct NewGame<'info> {
    #[account(mut, signer)]
    pub payer: Signer<'info>,
    /// CHECK:
    #[account(
        init_if_needed,
        payer = payer,
        space = 234,
        owner = token_program.key(),
    )]
    pub decent_book_mint: UncheckedAccount<'info>,
    /// CHECK:
    #[account(
        init_if_needed,
        payer = payer,
        space = 234,
        owner = token_program.key(),
    )]
    pub interesting_book_mint: UncheckedAccount<'info>,
    /// CHECK:
    #[account(
        init_if_needed,
        payer = payer,
        space = 234,
        owner = token_program.key(),
    )]
    pub fascinating_book_mint: UncheckedAccount<'info>,
    /// CHECK: PDA Mint authority
    #[account(seeds = [AUTHORITY_SEED], bump)]
    pub scientist_authority: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token2022>,
}

#[derive(Accounts)]
pub struct NewScientist<'info> {
    #[account(mut, signer)]
    pub payer: Signer<'info>,
    /// CHECK: New NFT mint
    #[account(
        init,
        payer = payer,
        space = 234,
        owner = token_program.key(),
    )]
    pub scientist_mint: UncheckedAccount<'info>,

    /// CHECK: PDA Mint authority
    #[account(mut, seeds = [AUTHORITY_SEED], bump)]
    pub scientist_authority: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token2022>,
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut, signer)]
    pub payer: Signer<'info>,
    #[account(
        init,
        payer = payer,
        associated_token::mint = scientist_mint,
        associated_token::authority = payer,
    )]
    pub scientist_account: InterfaceAccount<'info, TokenAccount>,
    #[account(
        init_if_needed,
        payer = payer,
        associated_token::mint = decent_book_mint,
        associated_token::authority = payer,
    )]
    pub decent_book_account: InterfaceAccount<'info, TokenAccount>,
    #[account(
        init_if_needed,
        payer = payer,
        associated_token::mint = interesting_book_mint,
        associated_token::authority = payer,
    )]
    pub interesting_book_account: InterfaceAccount<'info, TokenAccount>,
    #[account(
        init_if_needed,
        payer = payer,
        associated_token::mint = fascinating_book_mint,
        associated_token::authority = payer,
    )]
    pub fascinating_book_account: InterfaceAccount<'info, TokenAccount>,

    #[account(mint::authority = scientist_authority.key())]
    pub scientist_mint: InterfaceAccount<'info, Mint>,
    #[account(mint::authority = scientist_authority.key())]
    pub decent_book_mint: InterfaceAccount<'info, Mint>,
    #[account(mint::authority = scientist_authority.key())]
    pub interesting_book_mint: InterfaceAccount<'info, Mint>,
    #[account(mint::authority = scientist_authority.key())]
    pub fascinating_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: PDA Mint authority
    #[account(seeds = [AUTHORITY_SEED], bump)]
    pub scientist_authority: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token2022>,
    pub associated_token_program: Program<'info, AssociatedToken>,
}

#[derive(Accounts)]
pub struct Research<'info> {
    #[account(signer)]
    pub owner: Signer<'info>,
    /// CHECK:
    #[account(mut)]
    pub decent_book_account: InterfaceAccount<'info, TokenAccount>,
    /// CHECK:
    #[account(mut)]
    pub interesting_book_account: InterfaceAccount<'info, TokenAccount>,
    #[account(mut)]
    pub fascinating_book_account: InterfaceAccount<'info, TokenAccount>,

    /// CHECK:
    #[account(mut)]
    pub scientist_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub decent_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub interesting_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub fascinating_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: PDA Mint authority
    #[account(mut, seeds = [AUTHORITY_SEED], bump)]
    pub scientist_authority: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token2022>,
}

#[derive(Accounts)]
pub struct PublishBook<'info> {
    #[account(mut, signer)]
    pub owner: Signer<'info>,

    #[account(init_if_needed, payer = owner, space = 176, seeds = [GAME_ACCOUNT_SEED], bump)]
    pub game_account: Account<'info, GameAccount>,

    /// CHECK:
    #[account(mut)]
    pub decent_book_account: InterfaceAccount<'info, TokenAccount>,
    /// CHECK:
    #[account(mut)]
    pub interesting_book_account: InterfaceAccount<'info, TokenAccount>,
    #[account(mut)]
    pub fascinating_book_account: InterfaceAccount<'info, TokenAccount>,

    /// CHECK:
    #[account(mut)]
    pub scientist_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub decent_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub interesting_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub fascinating_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: PDA Mint authority
    #[account(mut, seeds = [AUTHORITY_SEED], bump)]
    pub scientist_authority: UncheckedAccount<'info>,

    /// CHECK: 
    #[account(mut)]
    pub highest_bidder: UncheckedAccount<'info>,

    /// CHECK: 
    #[account(mut)]
    pub previous_seller_scientist: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token2022>,
}

#[derive(Accounts)]
pub struct PlaceBid<'info> {
    #[account(mut, signer)]
    pub owner: Signer<'info>,

    #[account(mut, seeds = [GAME_ACCOUNT_SEED], bump)]
    pub game_account: Account<'info, GameAccount>,

    /// CHECK:
    #[account(mut)]
    pub decent_book_account: InterfaceAccount<'info, TokenAccount>,
    /// CHECK:
    #[account(mut)]
    pub interesting_book_account: InterfaceAccount<'info, TokenAccount>,
    #[account(mut)]
    pub fascinating_book_account: InterfaceAccount<'info, TokenAccount>,

    /// CHECK:
    #[account(mut)]
    pub scientist_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub decent_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub interesting_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK:
    #[account(mut, mint::authority = scientist_authority.key())]
    pub fascinating_book_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: PDA Mint authority
    #[account(mut, seeds = [AUTHORITY_SEED], bump)]
    pub scientist_authority: UncheckedAccount<'info>,

    /// CHECK: 
    #[account(mut)]
    pub previous_bidder: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token2022>,
}

#[account]
pub struct GameAccount {
    pub sale_book: Pubkey,
    pub seller: Pubkey,
    pub seller_scientist: Pubkey,
    pub highest_bidder: Pubkey,
    pub highest_bidder_scientist: Pubkey,
    highest_bid: u64,
}
