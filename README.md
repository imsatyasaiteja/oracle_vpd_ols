# Oracle OLS + VPD Based Judicial Database Security System

## Overview

This project demonstrates a **defense-in-depth database security architecture** for a Judicial Database Management System (JDMS) using **Oracle Database 23ai**.
The system combines:

- **Discretionary Access Control (DAC)** via Oracle roles
- **Mandatory Access Control (MAC)** via Oracle Label Security (OLS)
- **Row-level filtering** via Virtual Private Database (VPD)

The objective is to ensure that **judicial data confidentiality, integrity, and least-privilege access** are enforced *inside the database*, independent of application logic.

The design follows the **Bell-LaPadula model**:
- **No Read Up**
- **No Write Down**

---

## High-Level Architecture

Security is enforced at **three independent layers**:

1. **DAC** - defines what tables a role may access
2. **OLS (MAC)** - enforces clearance-based access using data labels
3. **VPD** - enforces per-case ownership and role-specific row visibility

---

## Initial Environment Setup

### 1. SSH Access to Oracle VM

```bash
ssh oracle@cs5322-1-i.comp.nus.edu.sg
```

> If connecting outside SoC, connect via **SoC VPN** first.

Default credentials:

* **User**: `oracle`
* **Password**: `dataBaseSecure`

---

### 2. Start Oracle Database Instance

```bash
sqlplus / as sysdba
```

```sql
STARTUP;
EXIT;
```

---

### 3. Start Oracle Listener

```bash
lsnrctl
```

```text
LSNRCTL> start
```

Listener runs on:

* **Host**: cs5322-1-i.comp.nus.edu.sg
* **Port**: 1521

---

### 4. SSH Tunneling (for SQL Developer)

Create an SSH tunnel:

* Local port: `1521`
* Remote host: `localhost`
* Remote port: `1521`
* SSH user: `oracle`

Then configure SQL Developer:

* **Hostname**: `localhost`
* **Port**: `1521`
* **Service Name**: `FREEPDB1`
* **Username**: `system`
* **Password**: `cs5322database`

---

## Database Setup Flow (Execution Order)

### Step 1: Create PDB and Admin User

```sql
@create_PDB_and_Admin.sql
```

Creates:

* Pluggable Database `JUDI_PDB`
* Administrative schema `JUDI_APP`

---

### Step 2: Create Core Tables

```sql
@"create tables.sql"
```

Tables created:

* `USERS`
* `CASES`
* `WITNESS`
* `EVIDENCE`
* `ACCESS_LOG`

---

### Step 3: Create Users, Roles, and Seed Data

```sql
@judi_roles_setup.sql
```

* Creates judicial roles
* Creates sample users
* Inserts sample cases, evidence, and witnesses

---

### Step 4: Enable Oracle Label Security (OLS)

```sql
@OLS_implementation.sql
```

This script:

* Enables OLS
* Creates policy `CASE_MAC2`
* Defines label hierarchy
* Applies policy to tables
* Assigns clearance ranges to users

---

### Step 5: Apply VPD Policies

```sql
@VPD_policies.sql
```

* Applies row-level predicates
* Restricts case visibility by role ownership

---

## Data Model and ER Diagram

<img src="/images/ER_diagram.png" width="90%"/>

### Core Entities

- Users: Stores all judicial users and their functional roles
- Cases: Central table containing case metadata and classification
- Witness: Stores witness information (always SEALED)
- Evidence: Stores evidence records (always SEALED)
- Access Log: Automatically records all access attempts for auditability

---

## Clearance Levels (OLS)

| Level | Label        | Description             |
| ----: | ------------ | ----------------------- |
|     0 | PUBLIC       | Open court records      |
|     1 | CONFIDENTIAL | Sensitive legal cases   |
|     2 | SEALED       | National security cases |

---

## Roles, Responsibilities and Privileges

### Clerk Roles

| Role         | Clearance | Capabilities                                            |
| ------------ | --------- | ------------------------------------------------------- |
| Junior Clerk | 0         | Read PUBLIC cases only                                  |
| Clerk        | 1         | Read PUBLIC and CONFIDENTIAL, write at level 1          |
| Senior Clerk | 2         | Read all, write SEALED cases; manage witness and evidence |

Clerks **cannot access**:

* `USERS`
* `ACCESS_LOG`

---

### Advocate

* Clearance: 2 (SEALED)
* **Read-only**
* VPD restricts access to **only assigned cases**

---

### Judge

* Clearance: 2
* Read-only access to all classified data
* VPD restricts access to **presiding cases only**

---

### Supreme Court Administrator

* Clearance: 2
* Read-only access to **all tables**
* Includes `USERS` and `ACCESS_LOG`

---

## Oracle Label Security (OLS)

### Policy Details

* **Policy Name**: `CASE_MAC2`
* **Label Column**: `SEC_LABEL2`
* **Protected Tables**:

  * `CASES`
  * `WITNESS`
  * `EVIDENCE`

<img src="/images/access_labels.png" width="90%"/>

### Enforcement

* **READ_CONTROL** - No Read Up
* **WRITE_CONTROL** - No Write Down / No Write Up
* Labels move with the data, not the user

---

## Virtual Private Database (VPD)

VPD enforces **horizontal isolation**:

* Judges -> only cases where `presiding_judge = user`
* Advocates -> only cases where `presiding_advocate = user`
* Clerks -> unrestricted within OLS clearance

This works **in addition to OLS**, not instead of it.

---

## Testing and Validation

### OLS Tests

```sql
@test_clerk2_example.sql
@test_clerk3_example.sql
```

<img src="/images/test_clerk3.jpeg" width="90%"/>

Expected results:

* Rows above clearance are silently filtered
* Invalid writes raise OLS authorization errors

---

### Verify Policies

```sql
SELECT object_name, policy_name
FROM dba_policies
WHERE object_owner = 'JUDI_APP';
```

---

## Security Guarantees Achieved

- Mandatory confidentiality enforcement
- No accidental data leakage
- Role and clearance based isolation
- Complete auditability
- Application-agnostic enforcement

---

## Limitations and Future Work

* Automatic label propagation via triggers
* Fine-Grained Auditing (FGA)
* Case lifecycle label downgrading
* Performance benchmarking

---

## Conclusion

This project demonstrates how **Oracle OLS + VPD** can enforce **real-world judicial security policies directly inside the database**, ensuring strong confidentiality guarantees even in the presence of malicious or buggy applications.

It serves as a blueprint for **regulated domains** such as judiciary, healthcare, and finance.
