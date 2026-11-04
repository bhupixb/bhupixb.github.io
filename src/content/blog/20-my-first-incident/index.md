---
title: "My first incident: a null pointer from an old token"
summary: "We added a new claim to our login token. Customers who still had an old token got an error on every page, and none of us could reproduce it."
date: "November 4 2026"
draft: false
tags:

- Incidents
- Java
- Learning

---

In July 2025, I caused my first production incident. A `NullPointerException`, in code I wrote.

It was an interesting one, because none of us could reproduce it.

### Some context

I work on a cloud SaaS product. Until then, a user belonged to exactly one account. We were building a feature to let one user belong to multiple accounts.

We use JWTs for login. The UI keeps the token in the browser's local storage and sends it with every API call. A token is valid for 24 hours.

Earlier, the JWT claims looked like this:

```json
{
  "userId": "user-123",
  "exp": 1751400000
}
```

For the new feature, the backend needs to know which account the user is currently working in. So we added an `accountId` claim, and the claims looked like this:

```json
{
  "userId": "user-123",
  "accountId": "account-456",
  "exp": 1751400000
}
```

On the backend, every HTTP request passes through an interceptor before it reaches a controller. It reads the JWT and puts who is calling (and now, from which account) into the logs and request context.

The interceptor runs for every request, unconditionally. Even APIs that don't need authentication, like loading app config or logging out, go through it.

```text
                 ┌─────────────┐     ┌─────────────┐     ┌────────────┐
HTTP request --> │ interceptor │ --> │ auth check  │ --> │ controller │
                 │ (every req) │     │ (if needed) │     │            │
                 └─────────────┘     └─────────────┘     └────────────┘
```

### The plan

We did think about old tokens. We knew tokens issued before the change wouldn't have `accountId`, and we made a deliberate plan for it. Ship this in two deploys:

1. First, start adding the `accountId` claim to every new token. Nothing reads it yet. Since tokens last 24 hours, a day later every valid token on prod would have `accountId`. Old tokens would simply be expired.
2. Then, ship the interceptor change that reads it.

With that order, a valid token without `accountId` can't exist by the time the interceptor reads it. A null check for it would be handling a case that never happens. So my change simply read it:

```java
String accountId = claims.get("accountId").toString();
```

It looked fine. But we missed two things.

First, in production both changes went out in the same deploy. The interceptor started reading `accountId` on the same day the first tokens with it were issued.

Second, even with a gap between the deploys, the plan had a hole. An expired token doesn't go away. It stays in local storage until the user logs in again or uses a different browser. Say someone logged in 10 days ago and hasn't come back since. We ship step 1 on day 5 and step 2 on day 10. They return on day 11, and their browser still sends the old token. The interceptor runs before the auth check, so it reads `accountId` from that token before anything rejects it as expired.

### "Customers can't even load the login page"

After the deploy, a customer posted in our shared Slack channel that the UI just said "Unexpected error occurred". No login page, no logout button, nothing else on the screen.

I tried to reproduce it. Logged in, logged out, tried an incognito tab. Everything worked. Same for everyone else on the team.

At that point I was just trying to figure out why would this even happen, and why only for these customers.

I checked the logs in Datadog and found the stack trace: a `NullPointerException` in the interceptor, on the line reading `accountId`.

That's when it clicked. These customers had logged in before the deploy, so their local storage still had the old token without `accountId`. `claims.get("accountId")` returned `null` and the interceptor crashed.

Because the interceptor sits in front of every controller, it didn't matter which API the UI called. When the UI loads, the first thing it does is fetch app config from the backend. That request returned a 500, so the UI never got far enough to show a login or logout option. The only way out was to clear local storage by hand.

### Why we didn't catch it

On staging, the plan went exactly as intended. We deployed the `accountId` claim first, and the interceptor change about a week later. By the time we tested the interceptor change, our tokens already had `accountId`.

On top of that, we log in and out all the time while testing different flows, switch users, open incognito tabs. None of us had a token old enough to hit the second hole either.

To catch this, you'd have to keep a session from before the deploy and use it after. Nobody does that unless they are looking for this exact problem.

### The fix

We could either make the backend handle a missing `accountId`, or handle it in the UI. The backend was written assuming `accountId` is always there, so the UI fix was simpler.

The UI decodes the token from local storage. If `accountId` is missing, it clears local storage and sends the user to the login page:

```js
const token = localStorage.getItem("token");
if (token && !decodeJwt(token).accountId) {
  localStorage.clear();
  window.location.href = "/login";
}
```

Old token: log in again and get a new one. New token: nothing happens.

### What I learned

1. Think about backward compatibility whenever you change the shape of something that outlives a deploy: tokens, cookies, cached values, queue messages, database rows. Before shipping, ask what happens when the new code meets:
   - data created before the change, including stale or expired data,
   - a user who hasn't been back in weeks,
   - changes meant to go out in order that land together, or in reverse,
   - a rollback to the previous version.
2. Don't rely on deploy order for correctness. Code that handles the missing field doesn't care about the order.
3. Be extra defensive in code that runs on every request. Enriching logs should never be able to take down an API.
4. Test the upgrade path, not just the new state: keep a session from before the deploy and use it after.

### Mistakes happen

This one was mine. Mistakes like this happen, and that's okay. Keep making mistakes but more importantly learn from them.

Until next time.
Happy Debugging.
