---
title: "Reverse Engineering a codebase"
summary: "Reverse Engineering a codebase with cli tools ripgrep(rg) and fd"
date: "Dec 5 2024"
draft: true
tags:
- Dev Skills
---

As developers, we frequently find ourselves trying to understand features in an unfamiliar and massive codebase.
Whether it's your team's internal project, someone else's code, or an open-source repository - making sense of it all can be quite daunting.
The first challenge? Simply figuring out where to begin!

Tools we will be using:
1. ripgrep or rg: An alternative of `grep` with default recursive search. [github](https://github.com/BurntSushi/ripgrep).
2. fd: An alternative of `find` command. [github](https://github.com/sharkdp/fd).
3. Any editor of your choice: VSCode, IntelliJ, Zed etc.

#### Lets Start
**Problem Statement**: Let's say you work in Digital Ocean RDS team, a Java codebase and want to understand how the automated backup system works for Postgres.

First thought would be to say open the codebase in InteliJ and search for "backup"?
The search results has 100's of matches, huh?

Let's do better & try using CLI, we'll start simple and with time add more filters.

Search for "backup" with `rg`:
```shell
$ rg backup
backend/app/src/main/pkg/file1.java
12:import io.company.backup;
28:    restore.backupUUID(id);

backend/app/test/resources/file2.json
5:    "backup_id": null,
41:      "backupData": null,
48:    "backup_id": null,

frontend/app/test/resources/file2.tsx
...

more files here...
```

This has a lot of files, we are only interested in `java` files atm. so let's add a fiter for that:
```shell
$ rg backup -type java
```

But wait this will not search words e.g. `class AutomatedBackup {}`, so let's do a case-insensitive search.

```shell
# -i means search case in-sensitive
$ rg backup -type java -i
```

Well, let's say there are 20+ files with `backup` keyword in it and each file is having 10-100 occurences of word `backup`. 
It will be overwhelming to just figure out which file to look at?

Maybe we can ignore the search results for now and only look a the file names first.

```shell
# -l says that only print the file names matching the query and not the actual lines
$ rg backup -type java -i -l
backend/app/src/main/pkg/AutomatedBackup.java
backend/app/src/main/pkg/PostgresRestore.java
backend/app/src/main/pkg/PostgresRestoreUtil.java
backend/app/src/main/pkg/AutomatedBackupImpl.java
backend/app/src/main/pkg2/BackupUtil.java
backend/app/src/test/pkg/AutomatedBackupImplTest.java
backend/app/src/test/pkg2/BackupUtilTest.java
more files ...
```

Now maybe we have some idea like `AutomatedBackupImpl` could be a good candiate to start looking at.
Open the file in IntelliJ, look at the methods defined and you are good to start. 

We can even lookup just the files having `backup` in it's name using `fd`:
```shell
# -i for case in-sensitive search
$ fd -i backup
backend/app/src/main/pkg/AutomatedBackup.java
backend/app/src/main/pkg/AutomatedBackupImpl.java
backend/app/src/main/pkg2/BackupUtil.java
```

This may be useful at times but it's not necessary that some files related to Backup functionality
will have `backup` in their file names.

#### Combining fd and rg

Now let's say you want to search for `backup` keyword in all files that have `backup` in their name.
If you see above our search results have files like `PostgresRestore.java` etc as well in results.

How to do it?
1. List all files having `backup` in their name: `$ fd -i backup --extension java`.
2. Search all files with keyword `backup`: `$ rg -i backup`

Combine the two: 
```shell
$ rg -i backup $(fd -i backup --extension java)
# Command substitution $() executes fd first to get list of backup files
# Then rg searches for 'backup' only in those files
```

#### Multine search

A very frequent use case is that during incidents or debugging we need to search for errors across code base.
If you simply use code editor search like VSCode or IntelliJ, they can take regex but don't support multiline search. On top of it, the commands are IDE specific.
I have one trick that may be helpful.

Sample code with multiline error message:
```java
backend/app/src/main/pkg/BackupStorageManager.java
89:        StorageMetrics metrics = getStorageMetrics();
90:        log.error(
91:            "S3 backup upload failed for instance {} to bucket {}. " +
92:            "Available storage: {}GB, Required: {}GB",
93:            instanceId, bucketName, metrics.getAvailable(), requiredSpace
94:        );
```

Let's say you encounter this error message in your logs:
```shell
S3 backup upload failed for instance i-123456 to bucket my-backup-bucket. Available storage: 10GB, Required: 50GB
```

Now if you search for this exact string or it's regex in code, you may not find anything because the error message is split across multiple lines in code.
In such cases you can split the string you are trying to search and use `-A/-C` flag in grep/rg.

```shell
# -A 5 means print 5 more lines after the matching line
$ rg "S3 backup upload failed" -A 5 | rg "Available storage"
```
I know this is a hypothetical example but I have used this trick a few times and it works in practice.

That's all I have for now :)
Happy Hacking!