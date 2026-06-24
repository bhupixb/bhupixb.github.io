---
title: "Text vs Binary Protocols"
summary: "A short note on what text and binary protocols really mean."
date: "June 24 2026"
draft: false
tags:
- Protocols
- HTTP
---

For the longest time, I heard people saying stuff like “Oh, that’s a binary protocol so it's fast!” but honestly, I never actually got what they really mean.

Also, how can something be a "binary protocol" if literally everything in a computer is already binary?

Well there are differences. Let's see each one by one:

### Text based protocol

HTTP/1.1 starts with something you can read:

```yaml
GET /hello HTTP/1.1
Host: example.com
Accept: text/html
```

If you capture this request in Wireshark or print the raw bytes, most of it looks like English text. The method is `GET`, the path is `/hello`, headers are `Name: value`, and lines end with `\r\n`.

The server can parse it by reading bytes until it finds known textual separators:

```text
GET /hello HTTP/1.1\r\n
Host: example.com\r\n
\r\n
```

Read a line. Split by spaces. Read more lines. Split each header at `:`. Stop when you hit the empty line.

This is why HTTP/1.1 is called text based. The control part of the protocol is text. 
You can open a TCP connection with `telnet` or `nc`, **type an HTTP request by hand**, and a server can understand it.

### Binary protocol

In a binary protocol, the parser usually **does NOT search** for textual separators. It reads fixed fields or length prefixed fields. This is the same reason [Redis RESP](/blog/redis-resp-protocol/) is pleasant to parse: once you know the length, you read exactly that many bytes and move on.

Postgres wire protocol messages are like that. A message starts with a one byte message type, then a four byte length, then the payload.

Roughly:

```text
[type: 1 byte][length: 4 bytes][payload: N bytes]
```

So the parser does something like:

1. Read 1 byte to know what message this is.
2. Read 4 bytes to know how long the message is.
3. Read exactly that many bytes.

There is no "find the next newline" step. The protocol tells you the size upfront.

### Why binary can be smaller

Say we want to send the number `1000`.

In a text protocol:

```text
1000
```

That is four ASCII bytes:

```text
31 30 30 30
```

In a binary protocol, a 32-bit integer can store the same value in four bytes too:

```text
00 00 03 e8
```

So for `1000`, both can take four bytes.

But now take `1000000000`.

As text:

```text
1000000000
```

That is ten bytes. As a 32-bit integer, it is still four bytes:

```text
3b 9a ca 00
```

That is one reason binary protocols can be more compact. They do not have to spell out numbers as digits.

There is another reason: text protocols often carry extra syntax. Header names, colons, spaces, CRLFs, quotes, commas, brackets, etc. This makes them easier to debug by humans, but there is a cost.

But binary does not magically make everything smaller. If you want to send the string `Hello`, those five ASCII characters are already five bytes. There is not much to compress at the protocol level unless you add compression, and that is a separate thing.

### Then how does HTTP send images?

This was the other thing that puzzled me.

If HTTP/1.1 is a text protocol, how can it send a JPEG, PDF, zip file, or anything else that is not text?

The answer is that HTTP's control section is text, but the body is just bytes.

Example:

```text
HTTP/1.1 200 OK
Content-Type: image/jpeg
Content-Length: 12345

[12345 bytes of JPEG data]
```

The headers are text. They describe the body. After the empty line, the client reads the body as bytes. It does not try to parse JPEG bytes as HTTP text.

`Content-Type` tells the client what those bytes mean. `Content-Length` tells it how many bytes to read. The browser then passes those bytes to the JPEG decoder, PDF viewer, or whatever handler matches the content type.

So HTTP being "text based" does not mean all data inside HTTP must be text. It means the framing and metadata are text.

Also, `Content-Length` is not the only way HTTP can frame a body. There is chunked transfer encoding too. I am using `Content-Length` here because it makes the byte-counting idea easier to see.

### What about emojis?

An emoji is a good example because it looks like one character in the UI.

You type this:

```text
hello 😀 world
```

On screen, `😀` feels like a single character. But when the browser sends it over HTTP, it does not send a tiny emoji object. It first encodes the text into bytes.

In UTF-8, the full string becomes:

```text
68 65 6c 6c 6f 20 f0 9f 98 80 20 77 6f 72 6c 64
```

The `hello` part is simple:

```text
68 -> h
65 -> e
6c -> l
6c -> l
6f -> o
```

The emoji is four bytes:

```text
f0 9f 98 80 -> 😀
```

HTTP carries those bytes in the request or response body. If the body is text, the sender can describe it with a header like:

```text
Content-Type: text/plain; charset=utf-8
```

Now the receiver knows how to decode the body bytes back into text. The browser decodes `f0 9f 98 80` as the Unicode code point for 😀, then the font/rendering layer draws the emoji on screen.

If you decode the same bytes as ASCII(instead of UTF-8), it fails at `f0`, because ASCII only knows bytes from `00` to `7f`.

That is why encoding matters. The network only moved bytes. UTF-8 is the agreement that lets both sides turn those bytes back into the same visible text.

HTTP does not magically assume UTF-8 for everything. The request line and header names are basically ASCII-shaped protocol text. The body is separate. If the body is an image, there is no UTF-8 decoding step. The bytes go to an image decoder.

### A tiny Python check

This is enough to see the difference:

```python
raw = "hello 😀 world".encode("utf-8")

print(raw)
print(raw.hex())

print(raw.decode("utf-8"))
print(raw.decode("ascii"))
```

```python
>> raw = "hello 😀 world".encode("utf-8")
>>>
>>> print(raw)
b'hello \xf0\x9f\x98\x80 world'
>>> print(raw.hex())
68656c6c6f20f09f988020776f726c64
>>>
>>> print(raw.decode("utf-8"))
hello 😀 world
>>> print(raw.decode("ascii"))
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
UnicodeDecodeError: 'ascii' codec can't decode byte 0xf0 in position 6: ordinal not in range(128)
```

That output is useful. Python is saying: this is not a `str`, this is a sequence of bytes. Printable ASCII bytes are shown as characters, but non-ASCII bytes are shown as hex escapes.

### TLDR

- Everything on the wire is bytes.

- A text protocol uses bytes that are meant to be read as text(via some encoding format, UTF-8 is most common?) for its framing. HTTP/1.1 request lines and headers are like that.

- A binary protocol uses byte positions, fixed sizes, length prefixes, and numeric fields more directly e.g. Postgres wire protocol.

- The payload can be anything in both cases. Text, image, PDF, zip, protobuf, JSON, whatever. The protocol only needs a way to say where the payload starts, how long it is, and how the receiver should interpret it.

