## Basic PostgreSQL Concepts

# PostgreSQL Monitoring Practice Task

## Objective

Run the provided PostgreSQL monitoring queries and demonstrate that they work correctly.

---

## Tasks

Execute the queries from the instruction and show the results for:

- Active sessions (`pg_stat_activity`)
- Currently active queries
- `pg_stat_statements` setup and query statistics
- Long-running queries (simulate if not exists)
- Blocked sessions and locks (simulate if not exists)

Additional system views:

- `pg_roles`
- `pg_database`
- `pg_stat_user_tables`

---

## Requirements

Students must:

- Execute all queries from the instruction
- Configure `pg_stat_statements`
- Show screenshots of query execution
- Provide a short explanation of the results

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

---

## 2. Currently Active Queries

Displays queries that are running right now with their execution duration.

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

---

## 3. User Query History (`pg_stat_statements`)

Provides query execution statistics such as number of calls, total execution time, average execution time, and executed SQL statements for a specific user.

Enable extension:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Check `postgresql.conf`:

```conf
shared_preload_libraries = 'pg_stat_statements'
```

## Set `shared_preload_libraries = 'pg_stat_statements'`

### 1. Open `postgresql.conf`

Find config file location

```bash
SHOW config_file;
```

```bash
sudo nano /Library/PostgreSQL/18/data/postgresql.conf
```

---

### 2. Find this line

```conf
#shared_preload_libraries = ''
```

or

```conf
shared_preload_libraries = ''
```

---

### 3. Replace with

```conf
shared_preload_libraries = 'pg_stat_statements'
```

If there are already other extensions:

```conf
shared_preload_libraries = 'pg_stat_statements,other_extension'
```

---

### 4. Save file

In `nano`:

- `CTRL + O` → Enter
- `CTRL + X`

---

### 5. Restart PostgreSQL

```bash
 sudo -u postgres /Library/PostgreSQL/18/bin/pg_ctl restart -D /Library/PostgreSQL/18/data
```
---

### 6. Verify setting

Connect to PostgreSQL and run:

```sql
SHOW shared_preload_libraries;
```

Expected result:

```text
pg_stat_statements
```

After PostgreSQL restart:

```sql
SELECT
    rolname,
    calls,
    total_exec_time,
    mean_exec_time,
    rows,
    query
FROM pg_stat_statements s
JOIN pg_roles r
    ON r.oid = s.userid
WHERE rolname = 'your_user'
ORDER BY total_exec_time DESC;
```

---

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

---

## 5. Blocked Sessions

Shows blocked queries and identifies which sessions are causing the locks.

```sql
SELECT
    blocked.pid     AS blocked_pid,
    blocked.query   AS blocked_query,
    blocking.pid    AS blocking_pid,
    blocking.query  AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_locks blocked_locks
    ON blocked.pid = blocked_locks.pid
JOIN pg_locks blocking_locks
    ON blocked_locks.locktype = blocking_locks.locktype
   AND blocked_locks.database IS NOT DISTINCT FROM blocking_locks.database
   AND blocked_locks.relation IS NOT DISTINCT FROM blocking_locks.relation
   AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity blocking
    ON blocking.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```