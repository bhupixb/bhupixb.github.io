---
title: "What I found in slow tests"
summary: "Less setup before each test and fewer builds of shared code. Two changes that removed work from our CI."
date: "October 7 2026"
draft: false
tags:
- Java
- Testing
- CI
---

Our Java tests spent about three seconds on setup before the test code started. Four CI jobs also built the same shared libraries independently. Both repeated work that made developers wait.

### Tests initialization speedup

Our suite had about **2,800 tests in total**. They ran in **four JVM forks in parallel**.

These were full application tests that called the actual HTTP server. Before each test, we truncated the Postgres tables and started the application. Other setup included user creation, generated account history, and service logins.

The structure looked like this:

```java
@BeforeEach // About 3 seconds for setup alone.
void setup() {
    // Truncate tables, start the application, and prepare test data.
}
@Test
void test1() {
    // Call the actual HTTP server and assert the result.
}
```

I instrumented the initialization code to see **where the total 2.8 seconds went**. I used a single class with ten empty tests. Each test ran setup through `@BeforeEach`, so I measured initialization without test logic.

I found five expensive areas. We then fixed each one:

- **Spec parsing:** Each test parsed the same YAML spec. We parsed it one time per JVM and used the result again.
- **Connection pool:** Each test created a new pool and destroyed it after the test. New Postgres connections are expensive: each starts a [new server process](https://www.postgresql.org/docs/17/tutorial-arch.html). We used the same pool for all tests in a class.
- **Database cleanup:** Each test ran `TRUNCATE` on the Postgres tables. We moved the data files to RAM to decrease that time.
- **Generated history:** User creation generated account history that these tests did not need. We removed it from the test setup.
- **Password checks:** Service logins ran `BCrypt` checks during setup. We bypassed them in these tests. Tests for password authentication must use the application password check.

Each test continued to start a new application and use truncated database tables. Shared connections must not retain an open transaction from the previous test.

![Test initialization before and after changes to spec reuse, database storage, connection pools, and fixture data.](./test-setup-before-after.png)

The median of three benchmark runs showed these changes in initialization time:

| Machine                      | Before   | After    | Reduction |
| ---------------------------- | -------: | -------: | --------: |
| Mac                          | 2,144 ms | 1,102 ms |     48.6% |
| Development server of CI type | 2,836 ms | 1,766 ms |     37.7% |

That saved about **one second per test**. If each fork ran 700 tests, the estimate is about 12 minutes less setup per fork.

This measures *test initialization*, not full CI time.

### CI build improvements

Four CI jobs built shared Java libraries **independently** for each pull request commit, even when those libraries did not change.

Each job also downloaded dependencies from Maven Central. We downloaded the same files often enough to receive `HTTP 429` responses: too many requests.

![Repeated CI dependency downloads receive HTTP 429 responses from Maven Central.](./maven-said.png)

We moved shared library builds into a job that published artifacts when the code changed. Test jobs downloaded those artifacts instead of compiling the same code again. The deployment job kept its own build.

The artifacts must match the source version, dependency versions, and build configuration. An old artifact could make a faster build check the wrong code.

For dependency downloads, we used **our internal GCP Maven Artifactory**, a GCP managed Maven proxy.

The proxy [downloads and caches a package version on its first request](https://docs.cloud.google.com/artifact-registry/docs/repositories/remote-overview#how-remote-repositories-work). Later requests for that version receive the cached copy. This reduced repeated downloads from Maven Central.

![Shared library build reuse and dependency downloads through the GCP repository.](./shared-build-and-mirror.png)

We also made some service checks conditional on changed files. Those rules include shared libraries and build configuration too.

The result was less compilation in test jobs and fewer dependency downloads from Maven Central. I do not have comparable measurements for the full CI time before and after these changes.
