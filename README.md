# Bank Management System — Oracle PL/SQL

A small banking database project built with **Oracle SQL and PL/SQL**. It covers customers, accounts, deposits, withdrawals, transfers, transaction history, and balance-change auditing.

## What it does

- Stores customers and their bank accounts
- Supports savings and current accounts
- Handles deposits, withdrawals, and transfers
- Checks account status and available balance before transactions
- Prevents negative balances with database constraints
- Records every financial transaction
- Keeps an audit record whenever an account balance changes
- Uses a PL/SQL package to keep the banking operations together
- Uses row locking for transfers to reduce concurrency problems
- Includes error handling and rollback for failed operations

## Database Design

The database relationships are documented in [docs/ER-DIAGRAM.md](docs/ER-DIAGRAM.md).

```text
CUSTOMERS
   │ 1
   │
   └──────────< ACCOUNTS
                    │ 1
                    │
                    └──────────< TRANSACTIONS

ACCOUNTS ──────────< ACCOUNT_AUDIT
```

### Tables

| Table | Purpose |
|---|---|
| `CUSTOMERS` | Customer details |
| `ACCOUNTS` | Account type, status and balance |
| `TRANSACTIONS` | Deposit, withdrawal and transfer records |
| `ACCOUNT_AUDIT` | Balance-change history |

## PL/SQL Package

The main operations are inside `BANK_PKG`:

- `GET_BALANCE` — checks an account balance
- `DEPOSIT_MONEY` — adds money to an active account
- `WITHDRAW_MONEY` — checks the balance and withdraws money
- `TRANSFER_MONEY` — moves money between two active accounts
- `CLOSE_ACCOUNT` — closes an account only when its balance is zero

The package also contains private validation procedures for transaction amounts and account status.

## Rules handled by the database

1. Transaction amounts must be greater than zero.
2. Only active accounts can be used for deposits, withdrawals, and transfers.
3. An account balance cannot go below zero.
4. A withdrawal or transfer is rejected when there is not enough money.
5. A transfer cannot be made from an account to itself.
6. Both accounts must be active for a transfer.
7. An account with a non-zero balance cannot be closed.
8. Failed banking operations are rolled back.
9. Balance changes are written to the audit table.

## Sample data

The demo uses two sample customers:

- **Ashutosh Kushwaha** — account `1001`
- **Palak Sharma** — account `1002`

The script then runs a deposit, withdrawal, and transfer and prints reports for the accounts, transactions, customer balances, and audit history.

## Testing

`tests.sql` contains basic checks for:

- Final account balances after the demo
- Number of transaction records
- Number of audit records
- Rollback after an insufficient-funds withdrawal
- `GET_BALANCE` function output

Run the main script first and then run `tests.sql`.

## Technologies

- Oracle Database
- SQL
- PL/SQL
- Stored Procedures
- Functions
- Packages / Package Body
- Triggers
- Sequences
- Exception Handling
- Transactions and Rollback
- Row-level locking
- Joins and aggregate queries

## How to run

1. Open **Oracle SQL Developer**, SQL*Plus, or SQLcl.
2. Connect to a development/test Oracle schema.
3. Enable `DBMS_OUTPUT`.
4. Run `bank_management_system.sql`.
5. Run `tests.sql`.
6. Check the generated reports and `PASS` messages.

> **Note:** The main script removes and recreates objects with this project's names so it can be run again. Use it only in a dedicated development/test schema.

## Project Structure

```text
plsql-bank-management-system/
├── bank_management_system.sql   # Schema, package, demo and reports
├── tests.sql                     # Basic automated checks
├── docs/
│   └── ER-DIAGRAM.md             # Database relationships
└── README.md                     # Project documentation
```

## Resume Description

**Bank Management System | Oracle SQL & PL/SQL**  
Built a relational banking database with customer, account and transaction management. Developed PL/SQL procedures and a package for deposits, withdrawals and account transfers, with validation, exception handling, row locking, rollback, triggers, audit logging and reporting queries.

## Note

This is a portfolio/learning project for demonstrating Oracle SQL and PL/SQL skills. It is not intended for real banking use.
