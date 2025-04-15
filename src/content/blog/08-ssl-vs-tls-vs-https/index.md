---
title: "SSL vs TLS vs HTTPS"
summary: "A quick difference between SSL/TLS/HTTPS"
date: "Apr 15 2025"
draft: false
tags:
- Notes
---

I am often confused between SSL vs TLS vs HTTPS. Each time I come across them I need to Google.
So I thought, let's understand and write about it.

SSL or TLS are both encryption-based security protocol i.e. they encrypt the data for Internet based communications.

SSL, or Secure Sockets Layer was developed first. It had some security flows, so TLS was developed to address
those.

Now in HTTP world, the data is sent across two computers on the internet in plain text form. SSL/TLS can be
used to encrypt this data(remember that these protocols are built specifically to do that). 
So the encrypted form(encrypted via SSL/TLS) of HTTP is called HTTPS.

