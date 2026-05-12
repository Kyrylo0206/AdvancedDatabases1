# PostgreSQL Monitoring & User Management Practice

## Objective

The goal of this task is to execute PostgreSQL monitoring queries, demonstrate their functionality, and configure a role-based access control system.

---

## Software Setup

To complete this practice, download and install the following tools:

* **PostgreSQL Server (v18.3)**: [Download from EnterpriseDB](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads)
* **DataGrip IDE**: [Download from JetBrains](https://www.jetbrains.com/datagrip/)

---

## Tasks

Execute the queries from the instruction and show the results for:

- Active sessions (`pg_stat_activity`)
- Currently active queries
- `pg_stat_statements` setup and query statistics
- Long-running queries (simulate if not exists)
- Blocked sessions and locks (simulate if not exists)
- Create a database role named **`monitor_user`** with restricted **Read-Only** access.

Additional system views:

- `pg_roles`
- `pg_database`
- `pg_stat_user_tables`


---

## Deliverables

Submit:

- SQL queries
- Screenshots with results
- Short conclusions about:
    - active sessions
    - query statistics
    - locks/blocking
    - table statistics


---


## Core Terminology

* **Session** — a connection between a user/application and the PostgreSQL database.
* **User** — a database role/account used to connect and execute queries.
* **Query** — an SQL command executed in the database (`SELECT`, `INSERT`, `UPDATE`, etc.).
* **Table statistics** — metadata about table activity, such as reads, inserts, updates, deletes, and table usage.

---

## System Views and Queries

### `pg_stat_activity`

Shows current database sessions and running queries.

### Active queries

Displays queries that are currently running.

### `pg_stat_statements`

Stores query execution history and performance statistics.

### Long-running queries

Helps identify queries running longer than expected.

### `pg_locks`

Shows locks and blocked sessions in the database.

### `pg_roles`

Contains information about PostgreSQL users and roles.

### `pg_database`

Displays information about databases in the PostgreSQL instance.

### `pg_stat_user_tables`

Provides usage and activity statistics for user tables.


---


## 1. Active Sessions

Shows all current database connections, including users, application names, session states, and executed queries.

```sql
SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    backend_start,
    query_start,
    query
FROM pg_stat_activity;
```

## 2. Currently Active Queries

**Note:** You can execute `SELECT pg_sleep(30);` in a separate session to simulate an active process.

```sql
SELECT
    pid,
    usename,
    now() - query_start AS duration,
    state,
    query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC;

```


## 3. Performance Statistics (`pg_stat_statements`)

Provides query execution statistics such as the number of calls, total execution time, average execution time, and executed SQL statements for a specific user.

### 1. Open `postgresql.conf`

First, find the exact path to your configuration file by running this command in your SQL console:

```sql
SHOW config_file;

```

**Copy the path provided in the output.**

* **macOS**:
Open the terminal and use the path from the query output:
```bash
sudo nano <paste_your_config_file_path_here>

```

* **Windows**:
Open **Notepad** (Run as Administrator), go to **File > Open**, and paste the path from the query output into the file name box.


### 2. Find this line

Search for the library setting within the file:

```conf
#shared_preload_libraries = ''

```

or

```conf
shared_preload_libraries = ''

```

### 3. Replace with

Update the setting to include the extension:

```conf
shared_preload_libraries = 'pg_stat_statements'

```

If other extensions are already listed, separate them with a comma:

```conf
shared_preload_libraries = 'pg_stat_statements,other_extension'

```


### 4. Save file

* **macOS (nano)**:
* `CTRL + O` → Enter
* `CTRL + X`


* **Windows (Notepad)**:
* `CTRL + S` to save and then close the editor.



### 5. Restart PostgreSQL

To apply the configuration changes, the database service must be restarted.

* **macOS**:
Use the directory path where your `postgresql.conf` is located (the "Data Directory"):
```bash
sudo -u postgres pg_ctl restart -D <path_to_your_data_directory>

```

* **Windows**:
1. Press `Win + R`, type **`services.msc`**, and press Enter.
2. Locate the service named **`postgresql-x64-18`** (or your specific version).
3. Right-click it and select **Restart**.


### 6. Verify setting

Enable the extension and verify that the libraries are loaded correctly:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

```

Run the following to confirm:

```sql
SHOW shared_preload_libraries;

```

**Expected result:**

```text
pg_stat_statements

```


## 4. Long-Running Queries

Finds active queries running longer than 5 minutes.

```sql
SELECT
    pid,
    usename,
    now() - query_start AS running_time,
    query
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - query_start > interval '5 minutes';
```


### 5. Blocked Sessions (Lock Analysis)

Identify queries that are stuck waiting for a lock and see which process is blocking them.

**Note:** To simulate blocking, start a transaction and modify a row in one session without committing, then attempt to modify the same row in a separate session.

```sql
SELECT
    blocked.pid     AS blocked_pid,
    blocked.query   AS blocked_query,
    blocking.pid    AS blocking_pid,
    blocking.query  AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_locks blocked_locks ON blocked.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocked_locks.locktype = blocking_locks.locktype
   AND blocked_locks.database IS NOT DISTINCT FROM blocking_locks.database
   AND blocked_locks.relation IS NOT DISTINCT FROM blocking_locks.relation
   AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity blocking ON blocking.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

```

## 8. Role Management (Read-Only User)

**Note:** Before proceeding, ensure no blocked sessions/locks remain from previous tasks; you can terminate lingering processes by running `SELECT pg_terminate_backend(pid);`

### Step 1: Create and Configure the Role

Run the following commands as a superuser to set up the limited account:

```sql
-- 1. Create the role with login capabilities
CREATE ROLE monitor_user WITH LOGIN PASSWORD 'secure_password';

-- 2. Grant connection and schema usage permissions
GRANT CONNECT ON DATABASE postgres TO monitor_user;
GRANT USAGE ON SCHEMA public TO monitor_user;

-- 3. Grant SELECT access to existing and future tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO monitor_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO monitor_user;

```

### Step 2: Verify Permissions

Perform the following steps to confirm the security configuration:

* **Connect as `monitor_user` with `secure_password`** using a new session.
* **Verify Read Access**: Execute a `SELECT` query on any table in the `public` schema to ensure data is visible.
* **Test Write Restrictions**: Attempt a non-READ action (e.g., `INSERT`, `UPDATE`, or `DELETE`).
* **Expected Result**: The database must return a `permission denied` error, confirming the role is strictly read-only.



