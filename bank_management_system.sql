CREATE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    customer_name VARCHAR2(50) NOT NULL,
    phone VARCHAR2(15),
    city VARCHAR2(30),
    created_at DATE DEFAULT SYSDATE
);

CREATE TABLE accounts (
    account_id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    balance NUMBER(12,2) CHECK (balance >= 0),
    account_type VARCHAR2(20),
    created_at DATE DEFAULT SYSDATE,
    
    CONSTRAINT fk_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

CREATE TABLE transactions (
    txn_id NUMBER PRIMARY KEY,
    account_id NUMBER,
    txn_type VARCHAR2(10),   -- DEPOSIT / WITHDRAW
    amount NUMBER(12,2),
    txn_date DATE DEFAULT SYSDATE,
    
    CONSTRAINT fk_account
    FOREIGN KEY (account_id)
    REFERENCES accounts(account_id)
);

CREATE SEQUENCE seq_customer START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_account  START WITH 1001 INCREMENT BY 1;
CREATE SEQUENCE seq_txn      START WITH 1 INCREMENT BY 1;


INSERT INTO customers VALUES (
    seq_customer.NEXTVAL,
    'Ashutosh',
    '9876543210',
    'Bhopal',
    SYSDATE
);

INSERT INTO accounts VALUES (
    seq_account.NEXTVAL,
    1,
    5000,
    'SAVINGS',
    SYSDATE
);

COMMIT;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Bank Account Management System Started');
END;
/

CREATE OR REPLACE FUNCTION get_balance (
    p_account_id NUMBER
) RETURN NUMBER IS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance
    FROM accounts
    WHERE account_id = p_account_id;

    RETURN v_balance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;
END;
/


SELECT get_balance(1001) FROM dual;


CREATE OR REPLACE PROCEDURE deposit_money (
    p_account_id NUMBER,
    p_amount NUMBER
) IS
BEGIN
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    INSERT INTO transactions VALUES (
        seq_txn.NEXTVAL,
        p_account_id,
        'DEPOSIT',
        p_amount,
        SYSDATE
    );

    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE withdraw_money (
    p_account_id NUMBER,
    p_amount NUMBER
) IS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance
    FROM accounts
    WHERE account_id = p_account_id;

    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient Balance');
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_account_id;

    INSERT INTO transactions VALUES (
        seq_txn.NEXTVAL,
        p_account_id,
        'WITHDRAW',
        p_amount,
        SYSDATE
    );

    COMMIT;
END;
/

DECLARE
    CURSOR txn_cursor IS
        SELECT txn_type, amount, txn_date
        FROM transactions
        WHERE account_id = 1001;

    v_txn txn_cursor%ROWTYPE;
BEGIN
    OPEN txn_cursor;
    LOOP
        FETCH txn_cursor INTO v_txn;
        EXIT WHEN txn_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            v_txn.txn_type || ' - ' ||
            v_txn.amount || ' on ' ||
            v_txn.txn_date
        );
    END LOOP;
    CLOSE txn_cursor;
END;
/


CREATE OR REPLACE TRIGGER prevent_negative_balance
BEFORE UPDATE OF balance ON accounts
FOR EACH ROW
BEGIN
    IF :NEW.balance < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Balance cannot be negative');
    END IF;
END;
/


SELECT c.customer_name, a.account_id, a.balance
FROM customers c
JOIN accounts a
ON c.customer_id = a.customer_id;



BEGIN
    withdraw_money(1001, 2000);
END;
/

UPDATE accounts SET balance = -500 WHERE account_id = 1001;









































