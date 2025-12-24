CREATE OR REPLACE FUNCTION CASE_SECURITY_POLICY (
    schema_var IN VARCHAR2,
    table_var  IN VARCHAR2
)
RETURN VARCHAR2
AS
    v_user VARCHAR2(128);
    v_clearance_level NUMBER;
    v_predicate VARCHAR2(2000);
BEGIN
    -- Get the current user
    v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');
    
    -- Determine user's clearance level based on their label
    -- Using the OLS label hierarchy: PUBLIC(0) < CONFIDENTIAL(1) < SEALED(2)
    
    IF v_user IN ('CLERK1') THEN
        v_clearance_level := 0; -- PUBLIC
    ELSIF v_user IN ('CLERK2') THEN
        v_clearance_level := 1; -- CONFIDENTIAL
    ELSIF v_user IN ('CLERK3') THEN
        v_clearance_level := 2; -- SEALED
    ELSIF v_user IN ('ADVOCATE1', 'ADVOCATE2', 'JUDGE1', 'JUDGE2', 
                     'COURT_ADMIN1', 'COURT_ADMIN2', 'JUDI_APP') THEN
        v_clearance_level := 2; -- SEALED (highest access)
    ELSE
        -- Default: no access
        RETURN '1=0';
    END IF;
    
    -- Build the predicate based on clearance level
    -- Users can see rows at or below their clearance level
    IF v_clearance_level = 0 THEN
        v_predicate := 'LABEL_TO_CHAR(SEC_LABEL2) = ''PUBLIC''';
    ELSIF v_clearance_level = 1 THEN
        v_predicate := 'LABEL_TO_CHAR(SEC_LABEL2) IN (''PUBLIC'', ''CONFIDENTIAL'')';
    ELSIF v_clearance_level = 2 THEN
        v_predicate := 'LABEL_TO_CHAR(SEC_LABEL2) IN (''PUBLIC'', ''CONFIDENTIAL'', ''SEALED'')';
    ELSE
        v_predicate := '1=0'; -- No access
    END IF;
    
    RETURN v_predicate;
END;
/

BEGIN
    -- Policy for CASES table
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'JUDI_APP',
        object_name     => 'CASES',
        policy_name     => 'CASE_VPD_POLICY',
        function_schema => 'JUDI_APP',
        policy_function => 'CASE_SECURITY_POLICY',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.SHARED_CONTEXT_SENSITIVE
    );

     DBMS_RLS.ADD_POLICY(
        object_schema   => 'JUDI_APP',
        object_name     => 'WITNESS',
        policy_name     => 'WITNESS_VPD_POLICY',
        function_schema => 'JUDI_APP',
        policy_function => 'CASE_SECURITY_POLICY',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.SHARED_CONTEXT_SENSITIVE
     );

         DBMS_RLS.ADD_POLICY(
        object_schema   => 'JUDI_APP',
        object_name     => 'EVIDENCE',
        policy_name     => 'EVIDENCE_VPD_POLICY',
        function_schema => 'JUDI_APP',
        policy_function => 'CASE_SECURITY_POLICY',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.SHARED_CONTEXT_SENSITIVE
    );
END;
/

BEGIN


     DBMS_RLS.DROP_POLICY(
        object_schema   => 'JUDI_APP',
        object_name     => 'CASES',
        policy_name     => 'WITNESS_VPD_POLICY'
     );

         DBMS_RLS.DROP_POLICY(
        object_schema   => 'JUDI_APP',
        object_name     => 'CASES',
        policy_name     => 'EVIDENCE_VPD_POLICY'
    );
END;
/

--- Test Queries ---
select object_name, policy_name, function, enable, policy_type from dba_policies where object_owner = 'JUDI_APP' order by object_name, policy_name;

SELECT * FROM JUDI_APP.WITNESS;