---
title: "Postgres COPY TO/FROM PROGRAM"
summary: "How Postgres COPY reads server files, runs OS commands, and can cross the boundary between SQL and the operating system."
date: "September 1 2026"
draft: false
tags:

- PostgreSQL

---

Postgres `COPY` is usually introduced as a way to move data between tables and files. But it can also send data to a program or read a program's output.

That second part is easy to overlook. It is also one reason managed Postgres providers do not give customers full superuser access.

### Copy table data to a file

I'll use this small table for the examples:

```sql
CREATE TABLE app_user (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO app_user (id, name)
VALUES
    (1, 'Asha'),
    (2, 'Ravi');
```

To write the table to a CSV file:

```sql
dev_db=# COPY app_user TO '/tmp/app_user.csv' WITH (FORMAT CSV, HEADER);
COPY 2
```

`COPY 2` means Postgres copied two rows.

The file is created on the database server, not on the computer where you run `psql` (unless they happen to be the same machine). Postgres writes it as the OS user running the database server.

On a Linux system with Postgres installed through `apt`, the OS user is usually named `postgres`:

```shell
postgres@ubuntu-01:~$ id
uid=100(postgres) gid=103(postgres) groups=103(postgres),102(ssl-cert)
```

The database role and OS user are two separate identities:

- The database role decides whether Postgres allows the SQL command.
- The OS user determines which files and programs the server process can access.

### Required database privileges

Server-side `COPY` still needs the usual table privileges. `COPY TO` needs `SELECT` on the source table, while `COPY FROM` needs `INSERT` on the destination table.

Files and programs require extra privileges:

- A database superuser or a member of `pg_write_server_files` can use `COPY TO 'file'`.
- A database superuser or a member of `pg_read_server_files` can use `COPY FROM 'file'`.
- A database superuser or a member of `pg_execute_server_program` can use `COPY ... PROGRAM`.

Without the required role, Postgres returns an error:

```sql
dev_db=> COPY app_user TO '/tmp/app_user.csv' WITH (FORMAT CSV, HEADER);
ERROR:  permission denied to COPY to a file
DETAIL:  Only roles with privileges of the "pg_write_server_files" role may COPY to a file.
HINT:  Anyone can COPY to stdout or from stdin. psql's \copy command also works for anyone.
```

These roles give a database user access outside the database itself. I would treat them with almost the same care as superuser access.

### Server-side `COPY` and client-side `\copy`

If you want the file on your local computer, use the `psql` `\copy` command:

```sql
dev_db=> \copy app_user TO '/tmp/app_user.csv' WITH (FORMAT CSV, HEADER)
COPY 2
```

Behind the scenes, `\copy` uses `COPY TO STDOUT` or `COPY FROM STDIN`. The `psql` client reads or writes the file, so it does not need the server-file roles listed above. The database user still needs the relevant table privileges.

The backslash makes an important difference:

- `COPY app_user TO '/tmp/app_user.csv'` writes on the database server.
- `\copy app_user TO '/tmp/app_user.csv'` writes on the `psql` client computer.

### Run a program with `COPY FROM PROGRAM`

`COPY FROM PROGRAM` starts a command on the database server and reads its standard output. Postgres inserts that output into the target table.

For a harmless example, here is the Linux `whoami` command:

```sql
CREATE TABLE command_output (data TEXT);

dev_db=# COPY command_output FROM PROGRAM 'whoami';
COPY 1

dev_db=# SELECT * FROM command_output;
   data
----------
 postgres
(1 row)
```

The result is `postgres` because that is the OS user running the database server. Your installation may use a different name.

Data can flow the other way too. This example sends the table to `gzip` and creates a compressed CSV on the database server:

```sql
dev_db=# COPY app_user TO PROGRAM 'gzip > /tmp/app_user.csv.gz'
             WITH (FORMAT CSV, HEADER);
COPY 2
```

Postgres passes the program string to the server's shell, which is why the `>` operator works here. Never put untrusted input in a `PROGRAM` command. It can lead to shell injection.

Only try these examples on a Postgres server you own or a disposable local setup, never on a shared or production server.

### Why `COPY ... PROGRAM` is sensitive

There is nothing special about `whoami` or `gzip`. `COPY ... PROGRAM` can run any command available to the Postgres OS user. Depending on the machine's permissions and network policy, that command could:

1. Read or write accessible files.
2. List processes and inspect details exposed by the operating system.
3. Open an outbound network connection.
4. Download and run another binary or script.

This command, for example, reads the process list into a table:

```sql
TRUNCATE command_output;

COPY command_output
FROM PROGRAM 'ps -eo user,pid,comm';

SELECT * FROM command_output LIMIT 5;
```

In practice, `pg_execute_server_program` is remote code execution as the Postgres OS user. It does not give root access by itself, but it does cross the boundary between SQL and the operating system.

### A reusable command runner

If you are experimenting on a disposable server, you can wrap `COPY FROM PROGRAM` in a function. This version redirects standard error to standard output, then base64-encodes the result so that Postgres can return multiline text as one value.

<details>
<summary>Show the <code>cmd_run</code> function</summary>

```sql
CREATE OR REPLACE FUNCTION cmd_run(cmd text)
    RETURNS text
    LANGUAGE plpgsql
AS $$
DECLARE
    result text;
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS
        cmd_output (data text)
        ON COMMIT DROP;

    TRUNCATE cmd_output;

    EXECUTE format(
            'COPY cmd_output FROM PROGRAM %L WITH (FORMAT text)',
            'sh -c ' || quote_literal(cmd || ' 2>&1 | base64 -w 0')
            );

    SELECT convert_from(decode(data, 'base64'), 'UTF8')
    INTO result
    FROM cmd_output;

    RETURN result;
END;
$$;
```

</details>

Once created, it can run a shell command and return the output:

```sql
SELECT * FROM cmd_run('ps aux | grep postgres');
```

This example expects a GNU/Linux `base64` command that supports `-w 0`. The function runs commands as the Postgres OS user, and the caller still needs permission to execute server programs. Do not expose it to untrusted database users or keep it around on a production server.

### Why managed Postgres restricts superuser access

AWS RDS, Google Cloud SQL, Supabase, and other managed Postgres providers do not give customers the full PostgreSQL `SUPERUSER` privilege. They provide restricted administrator roles instead. Supabase explicitly lists `COPY ... FROM PROGRAM` as unsupported. There are several reasons for that:

1. Full access to `COPY ... PROGRAM` would let a customer run operating-system commands inside the managed service.

2. The service has configuration files, logs, backups, and WAL-processing components. Customers must not be able to read or change provider-managed data through the database server.

3. Background services may send backups to object storage such as Amazon S3 or Google Cloud Storage. If the database process could read another service's credentials, a customer might use those credentials to access storage or copy data out of it. Providers separate these privileges to prevent that.

4. Process lists and configuration files may expose internal service names, monitoring endpoints, or API keys. A telemetry agent might send logs to Elasticsearch or Datadog, for example. Customers should not be able to inspect that agent through SQL.

5. Enterprise databases often sit in private VPCs or subnets behind a VPN or jump host. A server-side command could become another way to scan internal systems or move data out of the private network.

Managed providers need to keep database administration separate from OS administration. `COPY ... PROGRAM` is a good example of why.

### References

- [PostgreSQL: COPY](https://www.postgresql.org/docs/current/sql-copy.html)
- [AWS RDS: PostgreSQL roles and permissions](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Roles.html)
- [Google Cloud SQL: PostgreSQL users and roles](https://cloud.google.com/sql/docs/postgres/users)
- [Supabase: Roles, superuser access, and unsupported operations](https://supabase.com/docs/guides/database/postgres/roles-superuser)
