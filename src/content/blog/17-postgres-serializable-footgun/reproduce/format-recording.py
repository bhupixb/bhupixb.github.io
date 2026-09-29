"""Build a compact, edited replay of original-terminal.cast's name lookup test.

Run from any directory with Python 3. This presents the captured experiment;
it does not execute SQL or generate new database observations.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
OUTPUT = ROOT / "public/casts/psql-serializable-failure.cast"
ESC = "\x1b["
events = []
next_time = 0.25


def put(row, col, text, color=0):
    assert col in (1, 57) and len(text) <= 54
    return f"{ESC}{row};{col}H{ESC}{color}m{text}{ESC}0m"


def step(text, hold=0.25):
    """Display text, then leave it visible for hold seconds."""
    global next_time
    events.append([round(next_time, 2), "o", text])
    next_time += hold


def frame(caption):
    text = ESC + "2J" + ESC + "H" + ESC + "?25l"
    text += put(1, 1, "SESSION 1", "1;36")
    text += put(1, 57, "SESSION 2", "1;35")
    text += put(2, 1, "-" * 54) + put(2, 57, "-" * 54)
    for row in range(2, 14):
        text += f"{ESC}{row};55H│"
    text += put(14, 1, caption, "1;33")
    return text


step(frame("Both transactions read before either writes."), hold=1)
for col, row_id, balance in ((1, 1, 1100), (57, 2, 321)):
    step(put(3, col, "exp=> BEGIN ISOLATION LEVEL SERIALIZABLE;", "1;34"), hold=1)
    step(put(4, col, "BEGIN", "1;32"), hold=1)
    step(put(5, col, "exp=*> SELECT * FROM accounts", "1;34"))
    step(put(6, col, f"       WHERE name = 'user-{row_id}';", "1;34"), hold=1)
    step(put(8, col, " id |  name  | balance"))
    step(put(9, col, "----+--------+---------"))
    step(put(10, col, f"  {row_id} | user-{row_id} | {balance:7d}", "1;32"))
    step(put(11, col, "(1 row)"), hold=2)

step(frame("Different names; both scans hold table SIReadLocks."), hold=1)
for col, row_id, balance in ((1, 1, 111), (57, 2, 123)):
    step(put(3, col, "exp=*> UPDATE accounts", "1;34"))
    step(put(4, col, f"       SET balance = {balance}", "1;34"))
    step(put(5, col, f"       WHERE id = {row_id};", "1;34"), hold=1)
    step(put(6, col, "UPDATE 1", "1;32"), hold=1)

step(put(14, 1, "Both updates complete without waiting.".ljust(54), "1;33"), hold=1.5)
step(put(8, 1, "exp=*> COMMIT;", "1;34"), hold=1)
step(put(9, 1, "COMMIT", "1;32"), hold=1.5)
step(put(8, 57, "exp=*> COMMIT;", "1;34"), hold=1)
step(put(9, 57, "ERROR: could not serialize access due to", "1;31"))
step(put(10, 57, "read/write dependencies among transactions", "1;31"))
step(put(11, 57, "DETAIL: Canceled on identification as a pivot,", "1;31"))
step(put(12, 57, "during commit attempt.", "1;31"))
step(put(13, 57, "HINT: The transaction might succeed if retried.", "1;33"), hold=3)
step(put(14, 1, "Session 1 commits; Session 2 must retry.".ljust(54), "1;33"), hold=3)
# A terminal event preserves the final hold in players that use the last timestamp.
step(ESC + "0m", hold=0)

header = {
    "version": 2,
    "width": 110,
    "height": 15,
    "duration": events[-1][0],
    "title": "Different names, sequential scans, SERIALIZABLE failure (edited replay)",
    "env": {"TERM": "xterm-256color"},
}
OUTPUT.write_text("\n".join(json.dumps(item) for item in [header, *events]) + "\n")
print(f"Wrote {OUTPUT}: {len(events)} events, {events[-1][0]:.2f} seconds")
