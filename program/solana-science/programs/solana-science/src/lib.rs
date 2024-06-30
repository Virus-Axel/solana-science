use anchor_lang::prelude::*;
use anchor_lang::solana_program::{
    program::invoke,
    clock::Clock,
};
//    use solana_program::instruction::Instruction;
use anchor_spl::token_2022::{
    Token2022,
};
use anchor_spl::token_interface::{
    Mint,
    TokenAccount,
};
use anchor_spl::token_2022::spl_token_2022::extension::metadata_pointer::instruction::update;
use anchor_spl::token_2022_extensions::token_metadata::{
    token_metadata_update_field,
    TokenMetadataUpdateField,
};

declare_id!("Bp7LbjQdrAGGQft9TyJYiGvmKP6NzHZvvD35wiW12FMQ");

const AUTHORITY_SEED: &[u8] = b"SOLANA_SCIENCE_AUTHORITY_SEED";

#[program]
pub mod solana_science {

    use anchor_spl::token_interface::spl_token_metadata_interface::state::Field;

    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }

    pub fn research(ctx: Context<Research>) -> Result<()> {
        let clock = Clock::get()?;
        let unix_timestamp = clock.unix_timestamp;
        let update_accounts = TokenMetadataUpdateField{
            token_program_id: ctx.accounts.token_program.to_account_info(),
            metadata: ctx.accounts.scientist_mint.to_account_info(),
            update_authority: ctx.accounts.token_program.to_account_info(),
        };

        let cpi_context = CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            update_accounts,
            &[&[AUTHORITY_SEED]],
        );

        token_metadata_update_field(cpi_context, Field::Key("last_changed".to_string()), unix_timestamp.to_string())?;
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}

#[derive(Accounts)]
pub struct Research<'info>{
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
    #[account(seeds = [AUTHORITY_SEED], bump)]
    pub scientist_authority: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token2022>,
}
