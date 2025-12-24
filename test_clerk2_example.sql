-- Clerk2 Example: No Read up/No write down

-- Check the clerk2 policy and the lables:
SELECT SA_SESSION.LABEL('CASE_MAC2') FROM DUAL; --my session now
SELECT * FROM ALL_SA_USERS WHERE POLICY_NAME = 'CASE_MAC2';


------------------- No read up (Read down only) ----------------------
-- Select: can see only the rows with lable = 1,2 (confidential,public)
select * from JUDI_APP.CASES;



------------------- No write down-----------
-- Try insert is in his level (level 2) -> is OK
INSERT INTO JUDI_APP.CASES (title, case_number, status, DESCRIPTION)
VALUES ('Sealed Case', '2025-115', 'Closed', 'testing desc115');

select * from JUDI_APP.CASES WHERE case_number='2025-113';


-- Try insert is in lower/upper level (level 1,3) => no allowed
INSERT INTO JUDI_APP.CASES (title, case_number, status, DESCRIPTION,SEC_LABEL2)
VALUES ('Sealed Case', '2025-114', 'Closed', 'testing desc123',1);

INSERT INTO JUDI_APP.CASES (title, case_number, status, DESCRIPTION,SEC_LABEL2)
VALUES ('Sealed Case', '2025-114', 'Closed', 'testing desc123',3);

select * from JUDI_APP.CASES WHERE case_number='2025-114';
COMMIT;

-- Same for update
UPDATE JUDI_APP.CASES SET DESCRIPTION = 'new description updated' WHERE case_number = '2025-101';
select * from JUDI_APP.CASES WHERE case_number='2025-101';

-- Same for delete
DELETE FROM JUDI_APP.CASES WHERE case_number = '2025-101';
select * from JUDI_APP.CASES WHERE case_number='2025-101';

-- Even if try to change the session down to Public, he cannot write down he can only read
EXEC SA_SESSION.SET_LABEL('CASE_MAC2','PUBLIC');
SELECT SA_SESSION.LABEL('CASE_MAC2') FROM DUAL; -- My session now

INSERT INTO JUDI_APP.CASES (title, case_number, status, DESCRIPTION,SEC_LABEL2)
VALUES ('Sealed Case', '2025-114', 'Closed', 'testing desc123',1);

COMMIT;