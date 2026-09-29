#!/usr/bin/env bash
set -euo pipefail
export TERM=xterm-256color

session_name="serializable-blog-recording"
connection="psql -X -d exp -U ybcloud"
tmux_socket="serializable-blog"
tmux_cmd=(tmux -L "$tmux_socket" -f /dev/null)

send_sql() {
  local target="$1"
  local sql="$2"
  local escaped_sql="${sql//;/\\;}"
  "${tmux_cmd[@]}" send-keys -t "$target" -l "$escaped_sql"
  "${tmux_cmd[@]}" send-keys -t "$target" C-m
}

# Run setup.sql once in a fresh test database before recording.
# Reset only the two example balances; do not recreate an existing table.
psql -X -d exp -U ybcloud -v ON_ERROR_STOP=1 -c \
  "UPDATE accounts SET balance=CASE id WHEN 1 THEN 1100 ELSE 321 END WHERE id IN (1,2);" >/dev/null
"${tmux_cmd[@]}" kill-server 2>/dev/null || true
"${tmux_cmd[@]}" new-session -d -s "$session_name" -x 120 -y 24 "$connection"
"${tmux_cmd[@]}" split-window -h -t "$session_name":0 "$connection"
"${tmux_cmd[@]}" select-layout -t "$session_name":0 even-horizontal
"${tmux_cmd[@]}" select-pane -t "$session_name":0.0 -T "SESSION 1"
"${tmux_cmd[@]}" select-pane -t "$session_name":0.1 -T "SESSION 2"
"${tmux_cmd[@]}" set-option -t "$session_name" pane-border-status top
"${tmux_cmd[@]}" set-option -t "$session_name" pane-border-format " #{pane_title} "

(
  sleep 1
  send_sql "$session_name":0.0 "BEGIN ISOLATION LEVEL SERIALIZABLE;"
  sleep 0.7
  send_sql "$session_name":0.0 "SELECT * FROM accounts WHERE name='user-1';"
  sleep 1
  send_sql "$session_name":0.1 "BEGIN ISOLATION LEVEL SERIALIZABLE;"
  sleep 0.7
  send_sql "$session_name":0.1 "SELECT * FROM accounts WHERE name='user-2';"
  sleep 1
  send_sql "$session_name":0.0 "UPDATE accounts SET balance=111 WHERE id=1;"
  sleep 1
  send_sql "$session_name":0.1 "UPDATE accounts SET balance=123 WHERE id=2;"
  sleep 1
  send_sql "$session_name":0.0 "COMMIT;"
  sleep 1
  send_sql "$session_name":0.1 "COMMIT;"
  sleep 3
  "${tmux_cmd[@]}" detach-client -s "$session_name"
) &

"${tmux_cmd[@]}" attach-session -t "$session_name"
"${tmux_cmd[@]}" kill-server 2>/dev/null || true
