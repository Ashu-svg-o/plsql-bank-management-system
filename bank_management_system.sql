-- ============================================================
-- BANK MANAGEMENT SYSTEM
-- Oracle SQL & PL/SQL
-- ============================================================
-- Run in a fresh Oracle schema using SQL Developer, SQL*Plus,
-- or SQLcl with DBMS_OUTPUT enabled.
-- ============================================================

SET SERVEROUTPUT ON;
SET DEFINE OFF;

-- Safe cleanup for repeatable execution
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_account_audit'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_validate_transaction'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE bank_pkg'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE account_audit CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE transactions CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE accounts CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE customers CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_customer'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_account'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_txn'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_audit'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- SCHEMA
-- ============================================================
CREATE TABLE customers (
    customer_id   NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    phone         VARCHAR2(15) NOT NULL UNIQUE,
    city          VARCHAR2(50),
    created_at    TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_customer_name CHECK (LENGTH(TRIM(customer_name)) >= 2)
);

CREATE TABLE accounts (
    account_id    NUMBER PRIMARY KEY,
    customer_id   NUMBER NOT NULL,
    account_type  VARCHAR2(20) DEFAULT 'SAVINGS' NOT NULL,
    balance       NUMBER(14,2) DEFAULT 0 NOT NULL,
    status        VARCHAR2(15) DEFAULT 'ACTIVE' NOT NULL,
    created_at    TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_account_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    CONSTRAINT chk_account_type CHECK (account_type IN ('SAVINGS','CURRENT')),
    CONSTRAINT chk_account_balance CHECK (balance >= 0),
    CONSTRAINT chk_account_status CHECK (status IN ('ACTIVE','BLOCKED','CLOSED'))
);

CREATE TABLE transactions (
    txn_id        NUMBER PRIMARY KEY,
    account_id    NUMBER NOT NULL,
    txn_type      VARCHAR2(15) NOT NULL,
    amount        NUMBER(14,2) NOT NULL,
    txn_date      TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    description   VARCHAR2(200),
    CONSTRAINT fk_txn_account FOREIGN KEY (account_id)
        REFERENCES accounts(account_id),
    CONSTRAINT chk_txn_type CHECK (txn_type IN ('DEPOSIT','WITHDRAW','TRANSFER_IN','TRANSFER_OUT')),
    CONSTRAINT chk_txn_amount CHECK (amount > 0)
);

CREATE TABLE account_audit (
    audit_id      NUMBER PRIMARY KEY,
    account_id    NUMBER NOT NULL,
    old_balance   NUMBER(14,2),
    new_balance   NUMBER(14,2),
    changed_at    TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    changed_by    VARCHAR2(128) DEFAULT USER NOT NULL,
    action        VARCHAR2(20) NOT NULL
);

-- ============================================================
-- SEQUENCES & SAMPLE DATA
-- ============================================================
CREATE SEQUENCE seq_customer START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_account  START WITH 1001 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_txn      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_audit    START WITH 1 INCREMENT BY 1 NOCACHE;

INSERT INTO customers (customer_id, customer_name, phone, city)
VALUES (seq_customer.NEXTVAL, 'Ashutosh Kushwaha', '9876543210', 'Bhopal');

INSERT INTO customers (customer_id, customer_name, phone, city)
VALUES (seq_customer.NEXTVAL, 'Palak Sharma', '9876543211', 'Indore');

INSERT INTO accounts (account_id, customer_id, account_type, balance)
VALUES (seq_account.NEXTVAL, 1, 'SAVINGS', 10000);

INSERT INTO accounts (account_id, customer_id, account_type, balance)
VALUES (seq_account.NEXTVAL, 2, 'SAVINGS', 7500);

COMMIT;

-- ============================================================
-- VALIDATION & AUDIT TRIGGERS
-- ============================================================
CREATE OR REPLACE TRIGGER trg_validate_transaction
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    IF :NEW.amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Transaction amount must be greater than zero');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_account_audit
AFTER UPDATE OF balance ON accounts
FOR EACH ROW
WHEN (OLD.balance <> NEW.balance)
BEGIN
    INSERT INTO account_audit
        (audit_id, account_id, old_balance, new_balance, changed_at, changed_by, action)
    VALUES
        (seq_audit.NEXTVAL, :NEW.account_id, :OLD.balance, :NEW.balance,
         SYSTIMESTAMP, USER, 'BALANCE_CHANGE');
END;
/

-- ============================================================
-- BUSINESS LOGIC PACKAGE
-- ============================================================
CREATE OR REPLACE PACKAGE bank_pkg AS
    FUNCTION get_balance(p_account_id NUMBER) RETURN NUMBER;

    PROCEDURE deposit_money(
        p_account_id  NUMBER,
        p_amount      NUMBER,
        p_description VARCHAR2 DEFAULT 'Cash deposit'
    );

    PROCEDURE withdraw_money(
        p_account_id  NUMBER,
        p_amount       NUMBER,
        p_description  VARCHAR2 DEFAULT 'Cash withdrawal'
    );

    PROCEDURE transfer_money(
        p_from_account NUMBER,
        p_to_account   NUMBER,
        p_amount       NUMBER,
        p_description  VARCHAR2 DEFAULT 'Account transfer'
    );

    PROCEDURE close_account(p_account_id NUMBER);
END bank_pkg;
/

CREATE OR REPLACE PACKAGE BODY bank_pkg AS

    FUNCTION get_balance(p_account_id NUMBER) RETURN NUMBER IS
        v_balance accounts.balance%TYPE;
    BEGIN
        SELECT balance INTO v_balance
        FROM accounts
        WHERE account_id = p_account_id;
        RETURN v_balance;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Account does not exist: ' || p_account_id);
    END get_balance;

    PROCEDURE validate_amount(p_amount NUMBER) IS
    BEGIN
        IF p_amount IS NULL OR p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Amount must be greater than zero');
        END IF;
    END validate_amount;

    PROCEDURE validate_active_account(p_account_id NUMBER) IS
        v_status accounts.status%TYPE;
    BEGIN
        SELECT status INTO v_status
        FROM accounts
        WHERE account_id = p_account_id
        FOR UPDATE;

        IF v_status <> 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20003, 'Account is not active: ' || p_account_id);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Account does not exist: ' || p_account_id);
    END validate_active_account;

    PROCEDURE deposit_money(
        p_account_id NUMBER,
        p_amount NUMBER,
        p_description VARCHAR2 DEFAULT 'Cash deposit'
    ) IS
    BEGIN
        validate_amount(p_amount);
        validate_active_account(p_account_id);

        UPDATE accounts
        SET balance = balance + p_amount
        WHERE account_id = p_account_id;

        INSERT INTO transactions
            (txn_id, account_id, txn_type, amount, description)
        VALUES
            (seq_txn.NEXTVAL, p_account_id, 'DEPOSIT', p_amount, p_description);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Deposit successful. New balance: ' || get_balance(p_account_id));
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END deposit_money;

    PROCEDURE withdraw_money(
        p_account_id NUMBER,
        p_amount NUMBER,
        p_description VARCHAR2 DEFAULT 'Cash withdrawal'
    ) IS
        v_balance accounts.balance%TYPE;
    BEGIN
        validate_amount(p_amount);
        validate_active_account(p_account_id);

        SELECT balance INTO v_balance
        FROM accounts
        WHERE account_id = p_account_id
        FOR UPDATE;

        IF v_balance < p_amount THEN
            RAISE_APPLICATION_ERROR(-20004,
                'Insufficient balance. Available: ' || v_balance);
        END IF;

        UPDATE accounts
        SET balance = balance - p_amount
        WHERE account_id = p_account_id;

        INSERT INTO transactions
            (txn_id, account_id, txn_type, amount, description)
        VALUES
            (seq_txn.NEXTVAL, p_account_id, 'WITHDRAW', p_amount, p_description);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Withdrawal successful. New balance: ' || get_balance(p_account_id));
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END withdraw_money;

    PROCEDURE transfer_money(
        p_from_account NUMBER,
        p_to_account NUMBER,
        p_amount NUMBER,
        p_description VARCHAR2 DEFAULT 'Account transfer'
    ) IS
        v_from_balance accounts.balance%TYPE;
        v_from_status  accounts.status%TYPE;
        v_to_status    accounts.status%TYPE;
    BEGIN
        validate_amount(p_amount);

        IF p_from_account = p_to_account THEN
            RAISE_APPLICATION_ERROR(-20005, 'Source and destination accounts must differ');
        END IF;

        -- Lock accounts in deterministic order to reduce deadlock risk.
        IF p_from_account < p_to_account THEN
            SELECT balance, status INTO v_from_balance, v_from_status
            FROM accounts WHERE account_id = p_from_account FOR UPDATE;
            SELECT status INTO v_to_status
            FROM accounts WHERE account_id = p_to_account FOR UPDATE;
        ELSE
            SELECT status INTO v_to_status
            FROM accounts WHERE account_id = p_to_account FOR UPDATE;
            SELECT balance, status INTO v_from_balance, v_from_status
            FROM accounts WHERE account_id = p_from_account FOR UPDATE;
        END IF;

        IF v_from_status <> 'ACTIVE' OR v_to_status <> 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20006, 'Both accounts must be active');
        END IF;

        IF v_from_balance < p_amount THEN
            RAISE_APPLICATION_ERROR(-20004,
                'Insufficient balance. Available: ' || v_from_balance);
        END IF;

        UPDATE accounts
        SET balance = balance - p_amount
        WHERE account_id = p_from_account;

        UPDATE accounts
        SET balance = balance + p_amount
        WHERE account_id = p_to_account;

        INSERT INTO transactions
            (txn_id, account_id, txn_type, amount, description)
        VALUES
            (seq_txn.NEXTVAL, p_from_account, 'TRANSFER_OUT', p_amount, p_description);

        INSERT INTO transactions
            (txn_id, account_id, txn_type, amount, description)
        VALUES
            (seq_txn.NEXTVAL, p_to_account, 'TRANSFER_IN', p_amount, p_description);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Transfer successful: ' || p_amount ||
                             ' from ' || p_from_account || ' to ' || p_to_account);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'One or more accounts do not exist');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END transfer_money;

    PROCEDURE close_account(p_account_id NUMBER) IS
        v_balance accounts.balance%TYPE;
    BEGIN
        SELECT balance INTO v_balance
        FROM accounts
        WHERE account_id = p_account_id
        FOR UPDATE;

        IF v_balance <> 0 THEN
            RAISE_APPLICATION_ERROR(-20007,
                'Account cannot be closed while balance is ' || v_balance);
        END IF;

        UPDATE accounts
        SET status = 'CLOSED'
        WHERE account_id = p_account_id;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Account closed: ' || p_account_id);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Account does not exist: ' || p_account_id);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END close_account;

END bank_pkg;
/

-- ============================================================
-- DEMO
-- ============================================================
BEGIN
    bank_pkg.deposit_money(1001, 2500, 'Salary credit');
    bank_pkg.withdraw_money(1001, 1000, 'ATM withdrawal');
    bank_pkg.transfer_money(1001, 1002, 1500, 'Transfer to Palak');
END;
/

-- ============================================================
-- REPORTS
-- ============================================================
SELECT
    c.customer_id,
    c.customer_name,
    a.account_id,
    a.account_type,
    a.status,
    a.balance
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
ORDER BY c.customer_id, a.account_id;

SELECT
    t.txn_id,
    t.account_id,
    t.txn_type,
    t.amount,
    t.description,
    t.txn_date
FROM transactions t
ORDER BY t.txn_date, t.txn_id;

SELECT
    c.customer_name,
    COUNT(a.account_id) AS account_count,
    NVL(SUM(a.balance), 0) AS total_balance
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_balance DESC;

SELECT
    audit_id,
    account_id,
    old_balance,
    new_balance,
    changed_at,
    changed_by,
    action
FROM account_audit
ORDER BY audit_id;

-- Expected failure: demonstrates exception handling.
BEGIN
    bank_pkg.withdraw_money(1002, 999999, 'Insufficient funds test');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/
