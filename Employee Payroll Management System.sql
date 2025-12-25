CREATE TABLE departments (
    dept_id NUMBER PRIMARY KEY,
    dept_name VARCHAR2(40) NOT NULL
);

CREATE TABLE employees (
    emp_id NUMBER PRIMARY KEY,
    emp_name VARCHAR2(50) NOT NULL,
    dept_id NUMBER,
    basic_salary NUMBER(10,2) CHECK (basic_salary > 0),
    hire_date DATE DEFAULT SYSDATE,

    CONSTRAINT fk_emp_dept
    FOREIGN KEY (dept_id)
    REFERENCES departments(dept_id)
);

CREATE TABLE salary_details (
    salary_id NUMBER PRIMARY KEY,
    emp_id NUMBER,
    basic NUMBER(10,2),
    hra NUMBER(10,2),
    bonus NUMBER(10,2),
    tax NUMBER(10,2),
    net_salary NUMBER(10,2),
    salary_month VARCHAR2(10),
    generated_on DATE DEFAULT SYSDATE,

    CONSTRAINT fk_salary_emp
    FOREIGN KEY (emp_id)
    REFERENCES employees(emp_id)
);

CREATE SEQUENCE seq_dept START WITH 1;
CREATE SEQUENCE seq_emp START WITH 101;
CREATE SEQUENCE seq_salary START WITH 1;

INSERT INTO departments VALUES (seq_dept.NEXTVAL, 'HR');
INSERT INTO departments VALUES (seq_dept.NEXTVAL, 'IT');

INSERT INTO employees VALUES (
    seq_emp.NEXTVAL,
    'Ashutosh',
    2,
    30000,
    SYSDATE
);

COMMIT;

CREATE OR REPLACE FUNCTION calculate_tax (
    p_basic NUMBER
) RETURN NUMBER IS
BEGIN
    IF p_basic <= 25000 THEN
        RETURN p_basic * 0.05;
    ELSIF p_basic <= 50000 THEN
        RETURN p_basic * 0.10;
    ELSE
        RETURN p_basic * 0.15;
    END IF;
END;
/

CREATE OR REPLACE PACKAGE payroll_pkg IS
    PROCEDURE calculate_salary (
        p_emp_id NUMBER,
        p_month VARCHAR2
    );
END payroll_pkg;
/

CREATE OR REPLACE PACKAGE BODY payroll_pkg IS

    PROCEDURE calculate_salary (
        p_emp_id NUMBER,
        p_month VARCHAR2
    ) IS
        v_basic employees.basic_salary%TYPE;
        v_hra NUMBER;
        v_bonus NUMBER;
        v_tax NUMBER;
        v_net NUMBER;
    BEGIN
        SELECT basic_salary INTO v_basic
        FROM employees
        WHERE emp_id = p_emp_id;

        v_hra   := v_basic * 0.20;
        v_bonus := v_basic * 0.10;
        v_tax   := calculate_tax(v_basic);

        v_net := v_basic + v_hra + v_bonus - v_tax;

        INSERT INTO salary_details VALUES (
            seq_salary.NEXTVAL,
            p_emp_id,
            v_basic,
            v_hra,
            v_bonus,
            v_tax,
            v_net,
            p_month,
            SYSDATE
        );

        COMMIT;
    END calculate_salary;

END payroll_pkg;
/

CREATE OR REPLACE TRIGGER audit_salary_update
BEFORE UPDATE OF basic_salary ON employees
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Salary changed from ' || :OLD.basic_salary ||
        ' to ' || :NEW.basic_salary
    );
END;
/

DECLARE
    CURSOR payroll_cursor IS
        SELECT e.emp_name, d.dept_name, s.net_salary
        FROM employees e
        JOIN departments d ON e.dept_id = d.dept_id
        JOIN salary_details s ON e.emp_id = s.emp_id
        WHERE s.salary_month = 'SEP';

BEGIN
    FOR rec IN payroll_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            rec.emp_name || ' | ' ||
            rec.dept_name || ' | ' ||
            rec.net_salary
        );
    END LOOP;
END;
/

BEGIN
    payroll_pkg.calculate_salary(101, 'SEP');
END;
/

SELECT d.dept_name, SUM(s.net_salary) AS total_salary
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
JOIN salary_details s ON e.emp_id = s.emp_id
GROUP BY d.dept_name;

-- view department wise salary report

SELECT d.dept_name, SUM(s.net_salary) AS total_salary
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
JOIN salary_details s ON e.emp_id = s.emp_id
GROUP BY d.dept_name;



UPDATE employees
SET basic_salary = 40000
WHERE emp_id = 101;


























