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
- Uses savepoints so a failed operation can roll back its own changes without forcing a caller-wide rollback
- Leaves `COMMIT` control to the calling script instead of committing inside package procedures
- Includes exception handling for invalid and failed operations

## Database Design

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

See [`docs/ER-DIAGRAM.md`](docs/ER-DIAGRAM.md) for the Mermaid ER diagram.

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
- `CLOSE_ACCOUNT` — closes an active account only when its balance is zero

The package uses validation, row-level locking, savepoints and exception handling. Transaction boundaries are controlled by the caller, which allows multiple successful operations to be committed together.

## Rules handled by the database

1. Transaction amounts must be greater than zero.
2. Only active accounts can be used for deposits, withdrawals, and transfers.
3. An account balance cannot go below zero.
4. A withdrawal or transfer is rejected when there is not enough money.
5. A transfer cannot be made from an account to itself.
6. Both accounts must be active for a transfer.
7. An account with a non-zero balance cannot be closed.
8. Failed operations roll back to their operation savepoint.
9. Balance changes are written to the audit table.

## Sample data

The demo uses two sample customers:

- **Ashutosh Kushwaha** — account `1001`
- **Palak Sharma** — account `1002`

The script starts with balances of `10000` and `7500`. It then runs a deposit of `2500`, a withdrawal of `1000`, and a transfer of `1500` from account `1001` to account `1002`.

Expected final balances:

- Account `1001`: `10000`
- Account `1002`: `9000`

The transfer creates two transaction records: `TRANSFER_OUT` and `TRANSFER_IN`.

## Testing

`tests.sql` contains checks for:

- Final account balances after the demo
- Number of transaction records
- Number of audit records
- Rollback after an insufficient-funds withdrawal
- `GET_BALANCE` function output

Run the main script first and then run `tests.sql`.

The test script is provided for execution in Oracle; the repository does not claim a passing runtime result until it has been run against an Oracle database.

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
- Savepoints and Transactions
- Row-level locking
- Joins and aggregate queries
- Referential integrity and check constraints

## How to run

1. Open **Oracle SQL Developer**, SQL*Plus, or SQLcl.
2. Connect to a development/test Oracle schema.
3. Enable `DBMS_OUTPUT`.
4. Run `bank_management_system.sql` using **Run Script (F5)** in SQL Developer.
5. Run `tests.sql`.
6. Check the generated reports and `PASS` messages.

> **Note:** The main script removes and recreates objects with this project's names so it can be run again. Use it only in a dedicated development/test schema.

## Project Structure

```text
plsql-bank-management-system/
├── bank_management_system.sql   # Schema, package, demo and reports
├── tests.sql                     # Basic database checks
├── docs/
│   └── ER-DIAGRAM.md             # Database ER diagram
└── README.md                     # Project documentation
```

## Resume Description

**Bank Management System | Oracle SQL & PL/SQL**  
Built a relational banking database with customer, account and transaction management. Developed a PL/SQL package for deposits, withdrawals, transfers and account closure, using validation, exception handling, savepoints, row-level locking, triggers, audit logging, constraints and reporting queries.

## Note

This is a portfolio/learning project for demonstrating Oracle SQL and PL/SQL skills. It is not intended for real banking use.
