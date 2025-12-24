----------- Enabling OLS -----------------------------

-- as SYS 
sqlplus / as sysdba

--check the status 
SELECT * FROM DBA_OLS_STATUS; 

-- Register and Enable OLS
EXEC LBACSYS.CONFIGURE_OLS;
EXEC LBACSYS.OLS_ENFORCEMENT.ENABLE_OLS;
SHUTDOWN IMMEDIATE;
STARTUP;

-- Grants needed for JUDI_APP to work on the OLS functions

ALTER SESSION SET CONTAINER = JUDI_PDB;
GRANT LBAC_DBA TO JUDI_APP;
GRANT EXECUTE ON LBACSYS.SA_SYSDBA TO JUDI_APP;
GRANT EXECUTE ON LBACSYS.SA_COMPONENTS TO JUDI_APP;
GRANT EXECUTE ON LBACSYS.SA_LABEL_ADMIN TO JUDI_APP;
GRANT EXECUTE ON LBACSYS.SA_USER_ADMIN TO JUDI_APP;
GRANT EXECUTE ON LBACSYS.LBAC_POLICY_ADMIN TO JUDI_APP;
GRANT EXECUTE ON LBACSYS.SA_POLICY_ADMIN TO JUDI_APP;

-- From JUDI_APP user
-------------------first we implemented the DAC Part------------------------------
-- Create the roles:
CREATE ROLE JUNIOR_CLERK;
CREATE ROLE CLERK;
CREATE ROLE SENIOR_CLERK;
CREATE ROLE ADVOCATE_ROLE;
CREATE ROLE JUDGE_ROLE;
CREATE ROLE COURT_ROLE;

-- GRANT roles to the users
GRANT JUNIOR_CLERK TO CLERK1;
GRANT CLERK TO CLERK2;
GRANT SENIOR_CLERK TO CLERK3;
GRANT ADVOCATE_ROLE TO ADVOCATE1, ADVOCATE2;
GRANT JUDGE_ROLE TO JUDGE1, JUDGE2;
GRANT COURT_ROLE TO COURT_ADMIN1, COURT_ADMIN2;

-- Grant privilleges to roles
GRANT SELECT,INSERT, UPDATE ON CASES TO JUNIOR_CLERK;
GRANT SELECT,INSERT, UPDATE ON CASES TO CLERK;
GRANT SELECT,INSERT, UPDATE ON CASES TO SENIOR_CLERK;

GRANT SELECT,INSERT, UPDATE ON EVIDENCE TO SENIOR_CLERK; -- witness & evidence for senior only
GRANT SELECT,INSERT, UPDATE ON WITNESS TO SENIOR_CLERK;

GRANT SELECT ON EVIDENCE TO ADVOCATE_ROLE,JUDGE_ROLE,COURT_ROLE;
GRANT SELECT ON WITNESS TO ADVOCATE_ROLE,JUDGE_ROLE,COURT_ROLE;
GRANT SELECT ON CASES TO ADVOCATE_ROLE,JUDGE_ROLE,COURT_ROLE;
GRANT SELECT ON USERS TO COURT_ROLE;
GRANT SELECT ON ACCESS_LOG TO COURT_ROLE;

-------------DAC Checks--------------
-- Check users are created
SELECT 
    username
FROM 
    dba_users 
ORDER BY 
    username;

-- Check roles are created
SELECT 
    role 
FROM 
    dba_roles 
ORDER BY 
    role;

--check what each user has role:
SELECT 
    grantee,          -- user
    granted_role,     -- role assigned to the user
    admin_option,
    default_role
FROM 
    DBA_ROLE_PRIVS
WHERE 
    grantee IN (SELECT username FROM dba_users) -- filters out non-user grantees
ORDER BY 
    grantee, granted_role;

/*
SELECT 
    grantee,
    granted_role,
    admin_option,
    default_role
FROM 
    DBA_ROLE_PRIVS
WHERE 
    grantee = 'CLERK1';
*/

-- what each role have privilege on each table:
SELECT 
    PRIVILEGE, 
    TABLE_NAME, 
    ROLE
FROM 
    ROLE_TAB_PRIVS
WHERE 
    ROLE = 'ADVOCATE_ROLE';

---------------------------------- Creating the OLS Polices ----------------------
-- Check the existing OLS polices
SELECT * FROM ALL_SA_POLICIES;

-- Creating the CASES policy, one policy for all tables its name "CASES_MAC2"
BEGIN
  LBACSYS.SA_SYSDBA.CREATE_POLICY(
    policy_name      => 'CASE_MAC2',
    column_name      => 'SEC_LABEL2',
    default_options  => 'LABEL_DEFAULT'
  );
END;

SELECT * FROM ALL_SA_POLICIES; -- Check if the policy created

-- Create the levels for the policy
BEGIN
  LBACSYS.SA_COMPONENTS.CREATE_LEVEL('CASE_MAC2', 0, 'PUBLIC', 'PUBLIC');
  LBACSYS.SA_COMPONENTS.CREATE_LEVEL('CASE_MAC2', 1, 'CONFIDENTIAL', 'CONFIDENTIAL');
  LBACSYS.SA_COMPONENTS.CREATE_LEVEL('CASE_MAC2', 2, 'SEALED', 'SEALED');
END;

-- Create the lables for the policy (NOTE: labels should not be 0, value 0 is reserved for the system)
BEGIN
    LBACSYS.SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name => 'CASE_MAC2',
        label_tag   => 1,  -- non-zero ID
        label_value => 'PUBLIC' -- Maps to level_num 0
    );
    
    LBACSYS.SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name => 'CASE_MAC2',
        label_tag   => 2, 
        label_value => 'CONFIDENTIAL' -- Maps to level_num 1
    );
    
    LBACSYS.SA_LABEL_ADMIN.CREATE_LABEL(
        policy_name => 'CASE_MAC2',
        label_tag   => 3, 
        label_value => 'SEALED' -- Maps to level_num 2
    );
END;

--------------------- Few checks --------------
--View the Policy Itself
SELECT * FROM ALL_SA_POLICIES
WHERE POLICY_NAME = 'CASE_MAC2';

--View the Levels Created (S, P)
SELECT LEVEL_NUM, SHORT_NAME, LONG_NAME
FROM ALL_SA_LEVELS
WHERE POLICY_NAME = 'CASE_MAC2'
ORDER BY LEVEL_NUM DESC;

--View the Data Labels Created
SELECT LABEL_TAG, LABEL
FROM ALL_SA_LABELS
WHERE POLICY_NAME = 'CASE_MAC2';
-------------------------------------------


-- Apply the policy to the three tables
BEGIN 
    LBACSYS.LBAC_POLICY_ADMIN.APPLY_TABLE_POLICY(
        'CASE_MAC2',     -- policy_name
        'JUDI_APP',     -- schema_name
        'CASES',        -- table_name
        'ALL_CONTROL'  -- policy_options
    );
    LBACSYS.LBAC_POLICY_ADMIN.APPLY_TABLE_POLICY(
        'CASE_MAC2', 
        'JUDI_APP',
        'EVIDENCE', 
        'ALL_CONTROL'
    );
    LBACSYS.LBAC_POLICY_ADMIN.APPLY_TABLE_POLICY(
        'CASE_MAC2',
        'JUDI_APP',
        'WITNESS',
        'ALL_CONTROL'
    );
END;

-- Apply the policy to the other users
BEGIN
    LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'CLERK1',
        'PUBLIC',
        NULL,
        NULL,
        NULL
    );
    LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'CLERK2',
        'CONFIDENTIAL',
        NULL,
        NULL,
        NULL
    );

    LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'CLERK3',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
    LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'ADVOCATE1',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
        LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'ADVOCATE2',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
        LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'JUDGE1',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
        LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'JUDGE2',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
        LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'COURT_ADMIN1',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
        LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'COURT_ADMIN2',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
        LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'JUDI_APP',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
END;

-- for the JUDI_APP itself
BEGIN
        LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
        'CASE_MAC2',
        'JUDI_APP',
        'SEALED',
        NULL,
        NULL,
        NULL
    );
END;

---- edit clerk2: no read up/ no write down
BEGIN
  LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
      policy_name     => 'CASE_MAC2',
      user_name       => 'CLERK2',
      max_read_label  => 'CONFIDENTIAL',
      max_write_label => 'CONFIDENTIAL',
      min_write_label => 'CONFIDENTIAL',
      def_label       => 'CONFIDENTIAL',  
      row_label       => 'CONFIDENTIAL' 
  );
END;

-- for clerk3: write down up to level 2
BEGIN
  LBACSYS.SA_USER_ADMIN.SET_USER_LABELS(
      policy_name     => 'CASE_MAC2',
      user_name       => 'CLERK3',
      max_read_label  => 'SEALED',
      max_write_label => 'SEALED',
      min_write_label => 'CONFIDENTIAL',
      def_label       => 'SEALED',
      row_label       => 'SEALED' 
  );
END;
