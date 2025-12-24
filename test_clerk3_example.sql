-- Clerk3 Example: Read down / Write down only one level up to 2

-- Check the clerk3 policy and the lables:
SELECT SA_SESSION.LABEL('CASE_MAC2') FROM DUAL; -- My session now
SELECT * FROM ALL_SA_USERS WHERE POLICY_NAME = 'CASE_MAC2';


-------------- No read up (Read down only) ----------------------
-- Select: can see only the rows with lable = 1,2,3 (sealed,confidential,public)
select * from JUDI_APP.CASES;



------------------ Write down up tp level 2-----------
-- Try insert is in lower level (level 2) => is OK
INSERT INTO JUDI_APP.CASES (title, case_number, status, DESCRIPTION,SEC_LABEL2)
VALUES ('Sealed Case', '2025-114', 'Closed', 'testing desc123',2);

-- Try insert two level down (level 1) => not allowed
INSERT INTO JUDI_APP.CASES (title, case_number, status, DESCRIPTION,SEC_LABEL2)
VALUES ('Sealed Case', '2025-114', 'Closed', 'testing desc123',1);

select * from JUDI_APP.CASES WHERE case_number='2025-114';
COMMIT;

-- Same for update and delete (up to level 2)---
UPDATE JUDI_APP.CASES SET DESCRIPTION = 'new description updated' WHERE case_number = '2025-102';
select * from JUDI_APP.CASES WHERE case_number='2025-102';

UPDATE JUDI_APP.CASES SET DESCRIPTION = 'new description updated' WHERE case_number = '2025-101';
select * from JUDI_APP.CASES WHERE case_number='2025-101';

