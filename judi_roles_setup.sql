CREATE SEQUENCE users_seq
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE TABLE users (
    id NUMBER PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    full_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    role VARCHAR2(50) NOT NULL,
    clearance_level NUMBER(1) NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE OR REPLACE TRIGGER users_bir_trg
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := users_seq.NEXTVAL;
    END IF;
END;
/

INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('judge1','Dana Chaney','judge1@courts.gov','judge',3);
INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('judge2','Kristen Galvan','judge2@courts.gov','judge',3);
INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('clerk1','Sarah Smith','clerk1@courts.gov','clerk',1);
INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('clerk2','Kristina Martinez','clerk2@courts.gov','clerk',2);
INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('clerk3','Robert Williams','clerk3@courts.gov','clerk',3);
INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('advocate1','Mrs. Jacqueline Barker','advocate1@courts.gov','lawyer',3);
INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('advocate2','Sharon Sloan','advocate2@courts.gov','lawyer',3);
INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('court_admin1','Susan Richardson','court_admin1@courts.gov','court_admin',3);
INSERT INTO users (username, full_name, email, role, clearance_level) VALUES ('court_admin2','Brian Wright','court_admin2@courts.gov','court_admin',3);

COMMIT;

CREATE SEQUENCE cases_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE TABLE cases (
    id NUMBER PRIMARY KEY,
    case_number VARCHAR2(50) NOT NULL,
    status VARCHAR2(50) NOT NULL,
    title VARCHAR2(200) NOT NULL,
    description VARCHAR2(1000),
    presiding_advocate NUMBER REFERENCES users(id),
    presiding_judge NUMBER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    created_by NUMBER REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    updated_by NUMBER REFERENCES users(id)
);

COMMIT;

CREATE OR REPLACE TRIGGER judi_app.trg_cases_audit
BEFORE INSERT OR UPDATE ON judi_app.cases
FOR EACH ROW
DECLARE
    v_user_id NUMBER;
BEGIN
    -- Get the connected user's ID from the users table
    BEGIN
        SELECT id INTO v_user_id
        FROM users
        WHERE UPPER(username) = UPPER(SYS_CONTEXT('USERENV','SESSION_USER'));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_user_id := NULL; -- Or assign a default system user ID
    END;

    IF INSERTING THEN
        :NEW.id := cases_seq.NEXTVAL;
        :NEW.created_at := SYSTIMESTAMP;
        :NEW.created_by := v_user_id;
        :NEW.updated_at := SYSTIMESTAMP;
        :NEW.updated_by := v_user_id;
    ELSIF UPDATING THEN
        :NEW.updated_at := SYSTIMESTAMP;
        :NEW.updated_by := v_user_id;
    END IF;
END;
/

CREATE TABLE witness (
    id NUMBER PRIMARY KEY,
    full_name VARCHAR2(100) NOT NULL,
    statement VARCHAR2(2000),
    case_id NUMBER NOT NULL REFERENCES cases(id),
    contact_info VARCHAR2(200),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    created_by VARCHAR2(30) DEFAULT SYS_CONTEXT('USERENV', 'SESSION_USER') NOT NULL
);

-- Recreate the sequence
CREATE SEQUENCE witness_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Recreate the trigger
CREATE OR REPLACE TRIGGER witness_bir_trg
BEFORE INSERT ON witness
FOR EACH ROW
BEGIN
    -- Automatically assign ID from sequence
    IF :NEW.id IS NULL THEN
        :NEW.id := witness_seq.NEXTVAL;
    END IF;

    -- Automatically assign current database user
    IF :NEW.created_by IS NULL THEN
        :NEW.created_by := SYS_CONTEXT('USERENV', 'SESSION_USER');
    END IF;
END;
/


CREATE TABLE evidence (
    id NUMBER PRIMARY KEY,
    case_id NUMBER NOT NULL REFERENCES cases(id),
    evidence_type VARCHAR2(100) NOT NULL,
    description VARCHAR2(2000),
    file_url VARCHAR2(500),
    submitted_by NUMBER REFERENCES users(id),
    submitted_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE SEQUENCE evidence_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER evidence_bir_trg
BEFORE INSERT ON evidence
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := evidence_seq.NEXTVAL;
    END IF;
END;
/

CREATE TABLE access_log (
    id NUMBER PRIMARY KEY,
    user_id NUMBER NOT NULL,
    target_type VARCHAR2(50) NOT NULL,
    target_id VARCHAR2(50) NOT NULL,
    access_time TIMESTAMP NOT NULL,
    access_result VARCHAR2(20) NOT NULL,
    reason VARCHAR2(1000)
);

INSERT INTO access_log VALUES (1, 6, 'case', 'case1', TO_TIMESTAMP('2025-01-14T10:35:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Reviewing case documents for defense preparation.');
INSERT INTO access_log VALUES (2, 3, 'evidence', 'evidence1', TO_TIMESTAMP('2025-01-14T11:00:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Uploading financial records to evidence repository.');
INSERT INTO access_log VALUES (3, 7, 'evidence', 'evidence5', TO_TIMESTAMP('2025-03-03T09:20:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'denied', 'Attempted access to classified communications (Level 4).');
INSERT INTO access_log VALUES (4, 1, 'case', 'case3', TO_TIMESTAMP('2025-02-20T19:35:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Reviewing assault case for pretrial hearing.');
INSERT INTO access_log VALUES (5, 6, 'evidence', 'evidence2', TO_TIMESTAMP('2025-01-15T09:47:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Reviewing bank statements for cross-examination.');
INSERT INTO access_log VALUES (6, 2, 'evidence', 'evidence9', TO_TIMESTAMP('2025-06-25T16:55:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Reviewing forensic report for technical assessment.');
INSERT INTO access_log VALUES (7, 4, 'case', 'case10', TO_TIMESTAMP('2025-02-06T12:10:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Updating divorce settlement status.');
INSERT INTO access_log VALUES (8, 7, 'case', 'case5', TO_TIMESTAMP('2025-04-10T13:15:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Reviewing insider trading evidence.');
INSERT INTO access_log VALUES (9, 6, 'evidence', 'evidence7', TO_TIMESTAMP('2025-04-10T13:22:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'denied', 'Insufficient clearance for Level 3 evidence.');
INSERT INTO access_log VALUES (10, 8, 'evidence', 'evidence10', TO_TIMESTAMP('2025-07-11T10:33:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Reviewing classified intelligence brief.');
INSERT INTO access_log VALUES (11, 3, 'case', 'case2', TO_TIMESTAMP('2025-03-02T10:05:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'denied', 'Restricted Level 4 case — clerk clearance insufficient.');
INSERT INTO access_log VALUES (12, 1, 'evidence', 'evidence11', TO_TIMESTAMP('2025-03-30T15:05:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Reviewing forensic DNA report for ruling.');
INSERT INTO access_log VALUES (13, 6, 'case', 'case6', TO_TIMESTAMP('2025-05-18T09:25:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Viewing case summary before witness questioning.');
INSERT INTO access_log VALUES (14, 7, 'evidence', 'evidence4', TO_TIMESTAMP('2025-03-02T11:45:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'denied', 'Attempt to access Level 4 cargo manifest without clearance.');
INSERT INTO access_log VALUES (15, 2, 'case', 'case7', TO_TIMESTAMP('2025-06-25T16:35:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'granted', 'Reviewing cyber intrusion findings before verdict.');
INSERT INTO access_log VALUES (16, 5, 'case', 'case1', TO_TIMESTAMP('2025-01-14T10:35:00.000000','YYYY-MM-DD"T"HH24:MI:SS.FF'), 'denied', 'No write downs allowed.');
COMMIT;

-- Add users and grant access
BEGIN
    FOR r IN (SELECT username FROM dba_users
              WHERE username IN ('JUDGE1','JUDGE2','CLERK1','CLERK2','CLERK3','ADVOCATE1','ADVOCATE2','COURT_ADMIN1','COURT_ADMIN2')) LOOP
        EXECUTE IMMEDIATE 'DROP USER ' || r.username || ' CASCADE';
    END LOOP;
END;
/

CREATE USER judge1 IDENTIFIED BY "judge1";
CREATE USER judge2 IDENTIFIED BY "judge2";
CREATE USER clerk1 IDENTIFIED BY "clerk1";
CREATE USER clerk2 IDENTIFIED BY "clerk2";
CREATE USER clerk3 IDENTIFIED BY "clerk3";
CREATE USER advocate1 IDENTIFIED BY "advocate1";
CREATE USER advocate2 IDENTIFIED BY "advocate2";
CREATE USER court_admin1 IDENTIFIED BY "court_admin1";
CREATE USER court_admin2 IDENTIFIED BY "court_admin2";

-- Grant session privileges to all users

GRANT CREATE SESSION TO judge1, judge2, clerk1, clerk2, clerk3,
    advocate1, advocate2, court_admin1, court_admin2;


-- Grant table privileges to all users

-- Clerk1 & Clerk2: full access to cases
GRANT SELECT, INSERT, UPDATE, DELETE ON cases TO clerk1;
GRANT SELECT, INSERT, UPDATE, DELETE ON cases TO clerk2;

-- Clerk3: full access to cases, witness, evidence
GRANT SELECT, INSERT, UPDATE, DELETE ON cases TO clerk3;
GRANT SELECT, INSERT, UPDATE, DELETE ON witness TO clerk3;
GRANT SELECT, INSERT, UPDATE, DELETE ON evidence TO clerk3;

-- create role for the rest
CREATE ROLE advocate_role;
CREATE ROLE judge_role;
CREATE ROLE court_role;


-- Advocate1 & Advocate2: read-only access
GRANT SELECT ON cases TO advocate_role;
GRANT SELECT ON witness TO advocate_role;
GRANT SELECT ON evidence TO advocate_role;

GRANT advocate_role TO advocate1;
GRANT advocate_role TO advocate2;

-- Judge1 & Judge2: read-only access
GRANT SELECT ON cases TO judge_role;
GRANT SELECT ON witness TO judge_role;
GRANT SELECT ON evidence TO judge_role;

GRANT judge_role TO judge1;
GRANT judge_role TO judge2;

-- Court Admin1 & Court Admin2: read-only access to all main tables including users
GRANT SELECT ON cases TO court_role;
GRANT SELECT ON witness TO court_role;
GRANT SELECT ON evidence TO court_role;
GRANT SELECT ON users TO court_role;
GRANT SELECT ON access_log TO court_role;

GRANT court_role TO court_admin1;
GRANT court_role TO court_admin2;