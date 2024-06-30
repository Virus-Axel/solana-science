use anchor_lang::prelude::*;
use anchor_lang::solana_program::clock::Clock;

use anchor_lang::system_program::transfer;

use anchor_spl::{
    associated_token::AssociatedToken,
    token_2022::Token2022,
    token_2022_extensions::token_metadata::{
        token_metadata_initialize, token_metadata_update_field, TokenMetadataInitialize,
        TokenMetadataUpdateField,
    },
    token_interface::{
        initialize_mint2, metadata_pointer_initialize, InitializeMint2, MetadataPointerInitialize,
        Mint, TokenAccount,
    },
};

declare_id!("Bp7LbjQdrAGGQft9TyJYiGvmKP6NzHZvvD35wiW12FMQ");

const AUTHORITY_SEED: &[u8] = b"SOLANA_SCIENCE_AUTHORITY_SEED";

#[program]
pub mod solana_science {

    use anchor_lang::system_program::Transfer;
    use anchor_spl::token_interface::spl_token_metadata_interface::state::Field;

    use super::*;

    pub fn new_scientist(ctx: Context<NewScientist>) -> Result<()> {
        let init_accounts = TokenMetadataInitialize {
            token_program_id: ctx.accounts.token_program.to_account_info(),
            metadata: ctx.accounts.scientist_mint.to_account_info(),
            update_authority: ctx.accounts.scientist_authority.to_account_info(),
            mint: ctx.accounts.scientist_mint.to_account_info(),
            mint_authority: ctx.accounts.scientist_authority.to_account_info(),
        };

        let bump = ctx.bumps.scientist_authority;
        let signer_seeds: &[&[&[u8]]] = &[&[AUTHORITY_SEED, &[bump]]];

        let cpi_context =
            CpiContext::new(ctx.accounts.token_program.to_account_info(), init_accounts)
                .with_signer(signer_seeds);

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

        msg!("Scientist intialized");

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

        transfer(CpiContext::new(ctx.accounts.system_program.to_account_info(), Transfer{
            from: ctx.accounts.payer.to_account_info(),
            to: ctx.accounts.scientist_mint.to_account_info(),
        }), 1000000000)?;
        
        token_metadata_initialize(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                TokenMetadataInitialize {
                    token_program_id: ctx.accounts.token_program.to_account_info(),
                    metadata: ctx.accounts.scientist_mint.to_account_info(),
                    update_authority: ctx.accounts.scientist_authority.to_account_info(),
                    mint: ctx.accounts.scientist_mint.to_account_info(),
                    mint_authority: ctx.accounts.scientist_authority.to_account_info(),
                }).with_signer(signer_seeds),
            "name1".to_string(),
            "symbol1".to_string(),
            "http://uri1.se".to_string(),
        )?;
        msg!("Scientist created");
        Ok(())
    }

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }

    pub fn research(ctx: Context<Research>) -> Result<()> {
        let clock = Clock::get()?;
        let unix_timestamp = clock.unix_timestamp;
        let update_accounts = TokenMetadataUpdateField {
            token_program_id: ctx.accounts.token_program.to_account_info(),
            metadata: ctx.accounts.scientist_mint.to_account_info(),
            update_authority: ctx.accounts.token_program.to_account_info(),
        };

        let cpi_context = CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            update_accounts,
            &[&[AUTHORITY_SEED]],
        );

        token_metadata_update_field(
            cpi_context,
            Field::Key("last_changed".to_string()),
            unix_timestamp.to_string(),
        )?;
        Ok(())
    }
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
        init_if_needed,
        payer = payer,
        associated_token::mint = scientist_mint,
        associated_token::authority = payer,
    )]
    pub destination: InterfaceAccount<'info, TokenAccount>,
    #[account(mint::authority = scientist_authority.key())]
    pub scientist_mint: InterfaceAccount<'info, Mint>,
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
    #[account(
        mut,
        owner = token_program.key(),
        token::mint = scientist_mint.key(),
    )]
    pub scientist_token: InterfaceAccount<'info, TokenAccount>,
    #[account(mint::authority = scientist_authority.key())]
    pub scientist_mint: InterfaceAccount<'info, Mint>,
    /// CHECK: PDA Mint authority
    #[account(mut, seeds = [AUTHORITY_SEED], bump)]
    pub scientist_authority: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token2022>,
}
