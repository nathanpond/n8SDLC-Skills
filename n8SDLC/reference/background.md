# Background work

Rules for anything a session starts and doesn't wait on: a Bash call with `run_in_background`, a Monitor, a background subagent, a `ScheduleWakeup`, a `CronCreate` job. `/n8-subs` inventories them; this file is how they're launched and kept, so the inventory is rarely surprising.

The failure these rules exist for: a task hangs, nothing notifies, and the session sits idle — or worse, ends its turn with "waiting on X" — until the user asks. Silence looks exactly like "still running". Nothing in the harness escalates a task that never finishes; only the agent can, and only if it knew what "on time" meant when it launched.

## At launch

1. **Bounded by construction.** Every background command has an exit it reaches on its own: a condition loop with a deadline, never a bare `tail -f`, `--watch`, or `while true`. macOS has no `timeout`, so carry the deadline in the loop:

   ```bash
   end=$((SECONDS + 900))   # 15 min
   until <condition> || [ $SECONDS -ge $end ]; do sleep 5; done
   <condition> && echo READY || { echo "TIMEOUT after 15m"; exit 1; }
   ```

   A long-lived server (dev server, emulator) has no natural exit: it is launched once, recorded as `until stopped`, and stopped when the work that needed it is done.
2. **Monitors match every terminal state**: success, failure, crash, exit. A filter that only greps for the happy path stays silent through a crash loop. Monitors expire after at most 30 minutes; re-arm one only if its reason for existing still holds, and say so when you do.
3. **Say it in the same message**, one line per launch, visible to the user:

   `⏳ <id> — <what> · expect ~<duration> · ends when <condition> · then <what you'll do with it>`

   "Expect" is a real estimate (build ≈ last build's time, CI ≈ the last run's duration from `gh run list`); write `unknown` only when it is, and then pick a check-in time instead. This line is the record `/n8-subs` reads after the fact. A task with no line is an orphan the moment the context compacts.
4. **Never `&` or `nohup` inside a Bash call.** The process is reparented away from the session: no notification, no `TaskStop`, and invisible to `/n8-subs`'s process sweep. Use `run_in_background`, which is tracked.
5. **Foreground when you're going to wait anyway.** Backgrounding something and then doing nothing until it finishes adds a failure mode (a missed notification) and no parallelism. Background is for work that overlaps other work.

## While it runs

- **Overdue is a trigger.** A task past twice its estimate, or a Monitor with no events for longer than its expected event interval: read its output file tail (the path is in the launch result) and decide. Hung → `TaskStop` it and say so. Slow but progressing → re-estimate out loud. Don't keep waiting in silence.
- **Stop what you no longer need.** When the result stops mattering (the plan changed, a foreground run already answered it), `TaskStop` it in the same turn. A task nobody will read is noise in the next inventory, and sometimes it's still holding a port or a lock.
- **After a context compaction**, or whenever you're unsure what's live, run the `/n8-subs` sweep before launching anything new. Compaction drops the launch records, and the OS sweep is how you find what they described.

## Before ending a turn

If anything you started is still running, the reply says so: one line per task (id, what, running for, expected finish), and whether the next step waits on it. "I'll report when it finishes" is only true if a notification will actually arrive: a Bash background exit, a Monitor event, an agent completion, a scheduled wakeup. Otherwise say that the user needs to prompt you, or don't end the turn yet.

Never end a turn *only* to wait for a task that has no notification path. That is the hang.
