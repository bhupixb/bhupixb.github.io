---
title: "Redis RESP Protocol"
summary: "A short note on why Redis RESP is simple to parse."
date: "June 22 2026"
draft: true
tags:
- Redis
- Protocols
---

I was reading through the [Redis protocol spec](https://redis.io/docs/latest/develop/reference/protocol-spec/) recently and was really surprised with it's simplicity.

Redis clients and servers talk over RESP (Redis Serialization Protocol). It is a wire protocol, the format two programs use to exchange data over a network. The client sends commands in RESP, the server replies in RESP.

Let's try to understand it with a new data types:

### Basic rules

Every RESP value is terminated by `\r\n`. The first byte tells you the type:

```text
+ simple string
- error
: integer
$ bulk string
* array
( big number
```

Once you know the type byte, the rest is trivial.

### Integers

`:` followed by the number, terminated by `\r\n`.

```text
:1000\r\n
```

Read bytes after `:` until `\r\n`, parse as a number.

### Simple strings

`+` followed by the string, terminated by `\r\n`.

```text
+OK\r\n
```

*Do you notice any problem with above?*

It cannot contain `\r` or `\n`, else how will we identify terminating chars.

### Bulk strings

```text
$5\r\nhello\r\n
```

The `$5` says: read exactly 5 bytes after the first `\r\n`. The parser does not search inside the string for delimiters. It reads the length, reads that many bytes, skips the trailing `\r\n`.

Because it never interprets the content, this is binary-safe.

### Arrays

`*` followed by the element count.

```text
*3\r\n:1\r\n:2\r\n:3\r\n
```

Which is `[1, 2, 3]`.

The `*3` means: call the same RESP parser three more times, once per element. Arrays can contain any RESP type, including other arrays:
Similarly, your array can have different types of elements present together and can
use the same encoding rules.

### How commands are sent

Redis clients send commands as arrays of bulk strings. `SET name vicky` becomes:

```text
*3\r\n$3\r\nSET\r\n$4\r\nname\r\n$7\r\nbhupesh\r\n
```

Broken down:

```text
*3        three elements
$3 SET    first bulk string
$4 name   second bulk string
$7 vicky  third bulk string
```

The server knows exactly where each argument starts and ends because the lengths are declared upfront.

### Hey buy why not JSON?

JSON parsing is basically a bracket matching problem(actually much harder). You have `{`, `}`, `[`, `]`, quotes, escaped quotes, commas, and nesting. To parse it correctly you need to track depth, similar to the [valid parentheses](https://leetcode.com/problems/valid-parentheses/) problem. You push when you see an opening bracket, pop when you see a closing one, and you cannot be sure the structure is complete until the stack is empty.

On top of that, strings in JSON are tricky. You cannot just stop at the next `"` because the previous character might be a `\`. So the parser has to look back or track escape state while reading.

RESP does not have any of this. Bulk strings tell you exactly how many bytes to read. Arrays tell you exactly how many elements to expect. There is no bracket matching,  escape handling, or depth tracking. The parser just reads what it is told to read.

### References

- [Redis serialization protocol specification](https://redis.io/docs/latest/develop/reference/protocol-spec/)
