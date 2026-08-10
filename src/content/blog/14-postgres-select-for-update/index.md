---

title: "Postgres SELECT FOR UPDATE"
summary: "A short note on row locking with SELECT FOR UPDATE and SKIP LOCKED."
date: "August 10 2026"
draft: false
tags:

- PostgreSQL

---

Recently I worked on a few things that required some kind of locking in order
to avoid race conditions on some Database DML (insert/update/delete etc) operations.
We were using Postgres in this case.

In my case different tasks required synchronization/locking/coordination at different levels:

1. within same table.
2. across multiple tables.
3. across multiple tables and some external API calls.

I explored a few options including:

1. [PG advisory locks](https://www.postgresql.org/docs/current/explicit-locking.html#ADVISORY-LOCKS).
2. Locking specific row(s): via `[SELECT ... FOR UPDATE](https://www.postgresql.org/docs/current/explicit-locking.html#LOCKING-ROWS)`.
3. Or using a stricter transaction isolation level e.g. REPEATABLE READ or SERIALIZABLE isolation depending on usage.

In this post, we'll discuss (2) i.e. `SELECT ... FOR UPDATE` and its variations.

### SELECT ... FOR UPDATE

`FOR UPDATE` takes a lock on given rows. It is used to prevent these rows from being locked/modified/deleted by other transactions until the current transaction ends.

Let's take an example, where you have a `jobs` table, and you have 3 workers processing the jobs.

How do you ensure that one job is picked by exactly 1 worker?
One way to ensure that is by using `SELECT ... FOR UPDATE`:

```sql
BEGIN; -- t1

-- take a lock
WITH picked_jobs AS (
    SELECT id
    FROM jobs
    WHERE state = 'PENDING'
    ORDER BY id
    LIMIT 10
    FOR UPDATE
) -- 10 rows are locked until t1 is committed/aborted. Other transactions can't take a lock on them.

-- mark the rows as picked
UPDATE jobs
SET state = 'PICKED'
WHERE id IN (SELECT id FROM picked_jobs)
RETURNING *;

COMMIT;
```

Find 10 (or less) available jobs → lock them → mark them as picked → return them to the worker.

Also note that, if a row is locked and another transaction does a select on that row,
it waits until the transaction holding the row lock is committed/aborted.

With that in mind, do you notice any issues with the above approach?

### Comes lock contention

Lock contention on the same rows.

Of the N workers, each tries to pick the first 10 jobs,
whichever wins and gets a lock first, the rest N-1 wait until that transaction completes.
As you have more workers, you'll have more contention and waits.

### SKIP LOCKED

Comes `SKIP LOCKED` to the rescue (`SELECT ... FOR UPDATE SKIP LOCKED`).
As the name says, it will skip rows that are already locked. This allows each worker
to concurrently fetch a disjoint set of rows safely. This is also used in [pgmq](https://github.com/pgmq/pgmq/blob/main/docs/fifo-queues.md?plain=1#L123).

### Showtime: does SKIP LOCKED actually help?

I ran a small drain benchmark to check.

Setup: insert 1M pending rows, then 4 workers each pick batches of 50 until the table is empty. Same run with and without `SKIP LOCKED`, and with and without `ORDER BY id`.

Without `ORDER BY`:


| mode                     | time   | rows/s | p90   | p99   | p99.99 | avg   |
| ------------------------ | ------ | ------ | ----- | ----- | ------ | ----- |
| `FOR UPDATE`             | 6.209s | 161063 | 1.4ms | 4.6ms | 46.5ms | 1.2ms |
| `FOR UPDATE SKIP LOCKED` | 5.13s  | 194915 | 1.4ms | 1.8ms | 2.5ms  | 1ms   |


`SKIP LOCKED` was about **1.21x** faster wall-time. The interesting part is the tail: p99 ~**2.6x**, p99.99 ~**19x**.

With `ORDER BY id`:


| mode                     | time  | rows/s | p90   | p99   | p99.99 | avg   |
| ------------------------ | ----- | ------ | ----- | ----- | ------ | ----- |
| `FOR UPDATE`             | 6.42s | 155759 | 1.4ms | 6.6ms | 52.3ms | 1.3ms |
| `FOR UPDATE SKIP LOCKED` | 5.13s | 194917 | 1.4ms | 1.8ms | 10.1ms | 1ms   |


Same story: ~**1.25x** wall-time, p99 ~**3.8x**, p99.99 ~**5.2x**.

What I take away from this:

1. Avg/p90 barely moves. Most batches are fine either way. The pain shows up in the tail — those spikes are workers waiting on the same locked rows.
2. `ORDER BY id` makes plain `FOR UPDATE` a bit worse. All workers race for the same lowest ids first, so contention is more concentrated. That matches the lock-contention story above.
3. `SKIP LOCKED` keeps workers busy on different rows instead of sitting in line. Wall-time improves a bit; latency tails improve a lot.
4. Even with `SKIP LOCKED`, `ORDER BY` still costs something on the far tail (p99.99 10.1ms vs 2.5ms without it). Ordering is useful when you care about FIFO-ish pickup; skip it when you just want max drain throughput.
5. Zero deadlocks in all four runs. 

### When to use SELECT ... FOR UPDATE

- When you need to fetch a certain number of rows concurrently like in a job processing queue.
- Locking one or more rows to prevent them from concurrent modification/deletion.

Be very conscious that you do not end up:

1. locking lots of rows.
2. locking a small number of rows that are being accessed concurrently in the same path, as that will lead to lots of lock contention.
3. locking the rows in a long running transaction.

Another downside (that led me to NOT use it for our use-case) was:
All inserts on child tables WAIT for the `FOR UPDATE` lock to be released.

Say you have tables:

```sql
parent_table(id INT):
  -> child_table1 has Foreign Key on parent_table.id
  -> child_table2 has Foreign Key on parent_table.id
  ...
  -> child_tableN has Foreign Key on parent_table.id
```

So if you lock a parent row with `FOR UPDATE`, any INSERT into a child table that references that parent row waits until your transaction commits/aborts.

Why? Because while validating the foreign key, Postgres tries to take a `FOR KEY SHARE` lock on the parent row and that conflicts with `FOR UPDATE`.

So even "unrelated" child inserts (that only need to reference the parent id) get blocked. In our case, the parent table was a HOT table, and had 5+ child tables referencing it via Foreign Key.
If your parent rows are hot and child inserts are frequent, this hurts concurrency a lot.

I am sure there may be other ways to accomplish some of the things I shared above, please let me know if you are aware. Happy to discuss.

Until next time.

### References

- [https://www.postgresql.org/docs/current/explicit-locking.html#LOCKING-ROWS](https://www.postgresql.org/docs/current/explicit-locking.html#LOCKING-ROWS)
- [https://github.com/pgmq/pgmq](https://github.com/pgmq/pgmq)

