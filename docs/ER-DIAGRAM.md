# Database ER Diagram

The banking system uses four main tables. A customer can own multiple accounts, each account can have multiple transactions, and balance changes are recorded in the audit table.

```mermaid
erDiagram
    CUSTOMERS ||--o{ ACCOUNTS : owns
    ACCOUNTS ||--o{ TRANSACTIONS : records
    ACCOUNTS ||--o{ ACCOUNT_AUDIT : tracks

    CUSTOMERS {
        NUMBER customer_id PK
        VARCHAR2 customer_name
        VARCHAR2 phone UK
        VARCHAR2 city
        TIMESTAMP created_at
    }

    ACCOUNTS {
        NUMBER account_id PK
        NUMBER customer_id FK
        VARCHAR2 account_type
        NUMBER balance
        VARCHAR2 status
        TIMESTAMP created_at
    }

    TRANSACTIONS {
        NUMBER txn_id PK
        NUMBER account_id FK
        VARCHAR2 txn_type
        NUMBER amount
        TIMESTAMP txn_date
        VARCHAR2 description
    }

    ACCOUNT_AUDIT {
        NUMBER audit_id PK
        NUMBER account_id
        NUMBER old_balance
        NUMBER new_balance
        TIMESTAMP changed_at
        VARCHAR2 changed_by
        VARCHAR2 action
    }
```

## Relationships

- `CUSTOMERS.customer_id` → `ACCOUNTS.customer_id`
- `ACCOUNTS.account_id` → `TRANSACTIONS.account_id`
- `ACCOUNT_AUDIT.account_id` identifies the account whose balance changed.

## Notes

`ACCOUNT_AUDIT` intentionally keeps historical balance-change records independently from the main account workflow. The current project does not delete accounts, so audit history is retained for reporting.
