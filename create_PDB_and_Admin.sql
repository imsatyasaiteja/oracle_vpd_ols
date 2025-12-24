-- Connect as SYS
sqlplus / as sysdba
SELECT name, open_mode FROM v$pdbs;

SHOW CON_NAME; -- should be in the root

-- Create the PDB
CREATE PLUGGABLE DATABASE JUDI_PDB
  ADMIN USER JUDI_ADMIN IDENTIFIED BY "judiadmin"
  FILE_NAME_CONVERT = (
    '/opt/oracle/oradata/CS5322/pdbseed/',
    '/opt/oracle/oradata/CS5322/JUDI_PDB/'
  );

-- Open it and persist its state/ from squlplus/ sysdba terminal
ALTER PLUGGABLE DATABASE JUDI_PDB OPEN;
ALTER PLUGGABLE DATABASE JUDI_PDB SAVE STATE;

-- Verify it exists and is open
SELECT NAME, OPEN_MODE FROM V$PDBS;

-- Make sure the listener can see it (service registration)
-- still on the CDB root as SYSDBA
ALTER SYSTEM REGISTER;

-- Shows the service name 
SELECT NAME, NETWORK_NAME
FROM   V$SERVICES
WHERE  PDB = 'JUDI_PDB';

/*
Connect to the new PDB: Create a new connection in VS Code using your SSH tunnel:
Hostname: localhost
Port: 1521
Type: Service Name
Service Name: judi_pdb.comp.nus.edu.sg
User: JUDI_ADMIN
Password: judiadmin
*/

-- Inside JUDI_PDB: create tablespace, app schema, roles, users, and tables
-- Open a worksheet on the JUDI_PDB (JUDI_ADMIN) connection and run:

ALTER SESSION SET CONTAINER = JUDI_PDB;
SHOW CON_NAME; -- should display JUDI_PDB
GRANT CREATE USER, DROP USER, ALTER USER TO JUDI_ADMIN;
GRANT CREATE ROLE TO JUDI_ADMIN;
GRANT GRANT ANY PRIVILEGE, GRANT ANY ROLE TO JUDI_ADMIN;
