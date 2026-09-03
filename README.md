# Bank Management System — Oracle PL/SQL

A database-driven banking application built with **Oracle SQL and PL/SQL**. The project models customers and accounts, processes deposits, withdrawals and transfers, records transaction history, validates business rules, and maintains an audit trail for balance changes.

## Features

- Customer and bank-account management
- Savings/current account types and account status controls
- Deposit and withdrawal processing
- Inter-account fund transfers
- Balance lookup through a PL/SQL function
- Transaction history and reporting queries
- Insufficient-balance and invalid-input handling with `RAISE_APPLICATION_ERROR`
- Transaction validation and balance-audit triggers
- PL/SQL package specification/body for organized business logic
- Referential integrity, `CHECK` constraints and unique customer phone validation
- Sequences for generated customer, account, transaction and audit IDs
- Rollback on failed banking operations
- Deterministic row locking during transfers to reduce deadlock risk
- Repeatable setup script with cleanup and sample data

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

### Main tables

| Table | Purpose |
|---|---|
| `CUSTOMERS` | Customer master data |
| `ACCOUNTS` | Account type, status and current balance |
| `TRANSACTIONS` | Deposits, withdrawals and transfer entries |
| `ACCOUNT_AUDIT` | Historical balance-change audit trail |

## PL/SQL Architecture

The main banking operations are exposed through `BANK_PKG`:

- `GET_BALANCE` — returns the current account balance
- `DEPOSIT_MONEY` — validates and records deposits
- `WITHDRAW_MONEY` — validates funds and records withdrawals
- `TRANSFER_MONEY` — atomically moves funds between accounts
- `CLOSE_ACCOUNT` — closes an account only when its balance is zero

Supporting procedures handle amount and account-status validation internally.

## Business Rules

1. Transaction amounts must be greater than zero.
2. Only active accounts can perform banking operations.
3. An account cannot have a negative balance.
4. Withdrawals and transfers fail when funds are insufficient.
5. Source and destination accounts must be different for transfers.
6. Both accounts must be active for a transfer.
7. An account can only be closed when its balance is zero.
8. Failed operations are rolled back so partial transactions are not retained.
9. Balance changes are recorded in the audit table.

## Example Workflow

The demo section of the SQL script performs:

1. Deposit into **Ashutosh Kushwaha's** account.
2. Withdrawal for an ATM transaction.
3. Transfer from Ashutosh Kushwaha's account to **Palak Sharma's** account.
4. Account, transaction-history, customer-balance and audit reports.
5. An intentional insufficient-funds failure to demonstrate exception handling.

## Technologies

- Oracle Database
- SQL
- PL/SQL
- Stored Procedures
- Functions
- Packages / Package Body
- Triggers
- Transactions and Rollback
- Cursors / SQL reporting queries
- Constraints and Referential Integrity

## How to Run

1. Open **Oracle SQL Developer**, SQL*Plus or SQLcl.
2. Connect to a development Oracle schema.
3. Enable `DBMS_OUTPUT`.
4. Open `bank_management_system.sql`.
5. Run the complete script.
6. Review the generated account, transaction and audit reports.

> **Note:** The cleanup section intentionally drops objects belonging to this project so the script can be rerun in a dedicated development schema. Do not run it in a schema containing unrelated objects with the same names.

## Testing Scenarios

The script includes successful deposit, withdrawal and transfer flows plus an expected insufficient-funds failure. Manual tests should also cover invalid amounts, inactive accounts, self-transfers, missing accounts and closing an account with a non-zero balance.

## Project Structure

```text
plsql-bank-management-system/
├── bank_management_system.sql
└── README.md
```

## Resume Description

**Bank Management System | Oracle SQL & PL/SQL**  
Designed a relational banking database with customer, account and transaction management; implemented packaged PL/SQL business logic for deposits, withdrawals and atomic transfers with validation, exception handling, row-level locking and rollback; added triggers, audit logging, integrity constraints and reporting queries.

## Disclaimer

This is an educational portfolio project intended to demonstrate Oracle SQL/PLSQL database design and programming concepts. It is not production banking software.
