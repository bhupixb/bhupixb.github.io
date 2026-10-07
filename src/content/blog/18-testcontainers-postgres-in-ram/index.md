---
title: "A RAM disk cut my Postgres test setup by 83%"
summary: "I moved a disposable Testcontainers database to tmpfs. Per-test initialization fell to 17% of its previous time."
date: "September 30 2026"
draft: false
tags:

- PostgreSQL
- Java
- Testing

---

My Java test suite runs a real Postgres database with [Testcontainers](https://java.testcontainers.org/). Before each test, it truncates more than 50 tables so the next test starts with clean data.

That cleanup was expensive. I did not need the data after the test run, so writing it to disk made little sense.

**I moved the Postgres data directory to RAM. Per-test initialization fell to 17% of its previous time.**

### The change

Testcontainers starts Docker containers from Java test code. Its `withTmpFs` method can mount a memory-backed filesystem inside the container:

```java
import java.util.Map;

static final PostgreSQLContainer postgres =
    new PostgreSQLContainer("postgres:17.11")
        .withDatabaseName("test_db")
        .withUsername("test")
        .withPassword("test")
        .withTmpFs(Map.of(
            "/var/lib/postgresql/data", "rw,size=512m"
        ));
```

Postgres still reads and writes files, but those files now live on `tmpfs` instead of the container's disk. The database disappears when the container stops, which is exactly what I want from a disposable test database.

The path is correct for the Postgres 17 image used here. Check the image's `PGDATA` value if you use another version. The `512m` option sets a limit; it does not reserve all 512 MiB immediately.[^memory]

### Doesn't Testcontainers already disable fsync?

Yes. Testcontainers starts Postgres with:

```text
postgres -c fsync=off
```

This skips the durable flushes Postgres needs for crash recovery. It does not stop file writes or write-ahead log generation. `tmpfs` still helps because it changes where those files live.

This tradeoff is safe for my tests because I can recreate the database. I would not use it for production data or tests of crash recovery.[^command]

### What changed

With the Postgres data directory on `tmpfs`, per-test initialization took about **17% of its previous time**. That measurement includes truncating more than 50 tables before each test.

It does not mean the whole suite became 83% faster. Test logic, application code, and database queries still take time. The gain also depends on the machine's storage and available memory.

**A disposable database does not need durable storage.**

[^memory]: On Docker Desktop, the memory belongs to its Linux VM. `tmpfs` can also use swap under memory pressure.
[^command]: If you replace the container command with `withCommand(...)`, include `-c fsync=off` if you want to preserve Testcontainers' default.
