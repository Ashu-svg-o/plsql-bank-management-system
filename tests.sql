-- Basic checks for bank_management_system.sql
-- Run bank_management_system.sql first.

SET SERVEROUTPUT ON;

DECLARE
    v_balance_1001 NUMBER;
    v_balance_1002 NUMBER;
    v_txn_count    NUMBER;
    v_audit_count  NUMBER;
BEGIN
    SELECT balance INTO v_balance_1001
    FROM accounts
    WHERE account_id = 1001;

    SELECT balance INTO v_balance_1002
    FROM accounts
    WHERE account_id = 1002;

    IF v_balance_1001 <> 10000 THEN
        RAISE_APPLICATION_ERROR(-20101, 'Account 1001 balance test failed');
    END IF;

    IF v_balance_1002 <> 9000 THEN
        RAISE_APPLICATION_ERROR(-20102, 'Account 1002 balance test failed');
    END IF;

    SELECT COUNT(*) INTO v_txn_count FROM transactions;
    IF v_txn_count <> 4 THEN
        RAISE_APPLICATION_ERROR(-20103, 'Transaction count test failed');
    END IF;

    SELECT COUNT(*) INTO v_audit_count FROM account_audit;
    IF v_audit_count <> 4 THEN
        RAISE_APPLICATION_ERROR(-20104, 'Audit count test failed');
    END IF;

    DBMS_OUTPUT.PUT_LINE('PASS: balances, transactions and audit records are correct.');
END;
/

-- Failed withdrawal should not change the balance or add a transaction.
DECLARE
    v_before NUMBER;
    v_after  NUMBER;
    v_txn_before NUMBER;
    v_txn_after  NUMBER;
BEGIN
    SELECT balance INTO v_before
    FROM accounts
    WHERE account_id = 1002;

    SELECT COUNT(*) INTO v_txn_before FROM transactions;

    BEGIN
        bank_pkg.withdraw_money(1002, 999999, 'Test insufficient funds');
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    SELECT balance INTO v_after
    FROM accounts
    WHERE account_id = 1002;

    SELECT COUNT(*) INTO v_txn_after FROM transactions;

    IF v_before <> v_after THEN
        RAISE_APPLICATION_ERROR(-20105, 'Rollback test failed: balance changed');
    END IF;

    IF v_txn_before <> v_txn_after THEN
        RAISE_APPLICATION_ERROR(-20106, 'Rollback test failed: transaction was inserted');
    END IF;

    DBMS_OUTPUT.PUT_LINE('PASS: insufficient-funds operation was rolled back.');
END;
/

-- Function check
SELECT bank_pkg.get_balance(1001) AS account_1001_balance
FROM dual;
