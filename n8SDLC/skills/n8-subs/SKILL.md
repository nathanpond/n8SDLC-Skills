---
name: n8-subs
description: List everything this session has running in the background — subagents, background shells, monitors, scheduled wakeups and cron jobs — with what each is doing, how long it has run, when it should finish, and anything the user needs to know (overdue, silent, orphaned, finished but unreported). Cross-checks the agent's own launch records against the OS process tree, so work forgotten after a context compaction still shows up. Use whenever the user says "n8-subs", "what's running", "anything still going?", "is that still running", or a background task seems stuck.
---

# /n8-subs — Background Work Inventory

Tell the user exactly what's running on their behalf, and what's wrong with any of it. This command exists because a stale task only gets noticed when someone asks, so the answer must be complete and honest. It reads only, except for stops the user approves at the end.

Read `${CLAUDE_PLUGIN_ROOT}/reference/background.md`: it defines the launch records this skill reads and the overdue rule it applies.

## 1. Gather: four sources, all of them

Your memory of what you launched is one source, not the answer. Compaction drops launch records, and a subagent's own shells were never in your context at all.

1. **Your transcript.** Every `run_in_background` Bash result, Monitor, background Agent, `ScheduleWakeup` and `CronCreate` since the session began, with the `⏳` launch line if one was written. A task counts as finished only if its completion notification arrived or you stopped it. Keep, for each: id, kind, what it was for, launch time, estimate, output-file path.
2. **Agents:** `ListAgents` for subagents and teammates you can still message. Anything listed that has sent no completion is live.
3. **Schedules:** `CronList`, plus any `ScheduleWakeup` not yet fired. These aren't processes, but they will act later, and the user should know that.
4. **The OS**, which catches what the other three missed. Run this block as-is. It finds the `claude` process that owns this session and lists its tool shells (with the command each is running) and any other direct children. MCP servers and the harness's own `caffeinate` are filtered out, and so is the shell running the sweep:

   ```bash
   root=$PPID; p=$$
   while [ "${p:-1}" -gt 1 ]; do
     case "$(ps -o comm= -p "$p")" in *claude*) root=$p; break;; esac
     p=$(ps -o ppid= -p "$p" | tr -d ' ')
   done
   ps -A -o pid=,ppid=,etime=,command= | awk -v root="$root" -v self=$$ '
     { pid=$1; par[pid]=$2; et[pid]=$3; $1=$2=$3=""; cmd[pid]=substr($0,4) }
     END {
       for (p in par) if (par[p]==root && p!=self && cmd[p] ~ /shell-snapshots/) {
         c=cmd[p]; if (match(c, /eval .*< \/dev\/null/)) c=substr(c, RSTART+6, RLENGTH-19)
         n=0; for (q in par) { r=par[q]; while (r>1) { if (r==p) { n++; break } r=par[r] } }
         printf "SHELL pid=%s up=%s children=%d  %s\n", p, et[p], n, substr(c,1,160)
       } else if (par[p]==root && p!=self && cmd[p] !~ /(mcp|caffeinate)/) {
         printf "OTHER pid=%s up=%s  %s\n", p, et[p], substr(cmd[p],1,160)
       }
     }'
   ```

   `up=` is elapsed time (`[[dd-]hh:]mm:ss`). Empty output means no tool shell is alive. It does **not** prove that no subagent is running, since agents aren't child processes; that's what source 2 is for. A process started with `&` or `nohup` inside a foreground command has been reparented away from `claude` and won't show here. If one is suspected (a port is held, a dev server answers), `lsof -nP -iTCP -sTCP:LISTEN` finds it by port, and it goes in the report as unattributed.

**Reconcile.** Match each OS shell to a transcript task by command. A shell with no match is an **orphan**, most often one launched before a compaction. Name it by its command and runtime, and don't guess its purpose. A transcript task with no live shell and no completion notification is **lost**: it died without notifying, so read its output file for how.

## 2. Assess each live item

Read the tail of each output file (`tail -n 20 <path>`) and check its modification time (`stat -f %m <path>`, then compare with `date +%s`). Then pick a status:

- **ok**: within its estimate, and output is advancing or the task isn't expected to print.
- **overdue**: past twice its estimate. Say what the tail shows: progressing, stuck on a line, or waiting on input it will never get.
- **silent**: a Monitor or log-watcher with no events or output for longer than its expected interval. Remember that silence is not success.
- **orphan** / **lost**: from the reconcile step above.
- **done, unreported**: finished, but its result never reached the user. Give the result now.
- **scheduled**: a wakeup or cron that hasn't fired yet. Give the next fire time.

For "expected completion", use the launch line's estimate. If there isn't one, estimate from the evidence (a test suite's last run time, a CI run's history from `gh run list`) and mark it `~est.`, or write `unknown`. A made-up precise number is worse than `unknown`.

## 3. Report

```
## Background work — <n> live

| ID | Kind | Task | Running | Expected | Status | Notes |
|---|---|---|---|---|---|---|
| b83z4dofg | shell | npm test (full suite) | 12m | ~4m | ⚠ overdue | tail stuck on "connecting to db" since 11:02 |
| agent-3 | subagent | verify S14 AC table | 6m | ~10m | ok | |
| pid 71220 | shell | vite dev server | 2h14m | until stopped | orphan | launched before compaction; holds :5173 |
| — | wakeup | re-check CI on PR #41 | fires 14:40 | | scheduled | |

⚠ Needs you: <one line per item where a decision is the user's: stop it, keep waiting, or it's done and here's the result>
```

Nothing running → say so in one line, and name anything that finished unreported. Don't render an empty table.

Notes carry what the user can't see from the table: what the next step waits on, what a hung task is holding (a port, a lock, a worktree), and whether stopping it loses work.

## 4. Offer the stops

List what you'd stop and why: overdue with no progress, orphans, and anything whose result no longer matters. Ask once, as one question covering them all. On approval, use `TaskStop <id>` for tasks the harness knows. For an orphan pid, `kill <pid>` and then confirm it's gone with `ps -p <pid>`. A shell's children usually die with it; if the sweep still shows them, kill those too. Stopping a subagent discards its unfinished work, so say that in the question. Never stop anything unasked. A dev server the user is actively using looks exactly like an orphan to you.
