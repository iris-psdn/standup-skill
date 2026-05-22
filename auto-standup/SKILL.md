---
name: auto-standup
description: Draft my daily Trinity standup, confirm it with me, then send it to Trinity in Slack automatically.
user-invocable: true
---

You are helping me write my daily standup report. Pull my activity, draft the standup, then confirm it with me before sending to Trinity. Do **not** ask questions during data collection — just draft and present.

## Step 0 — First-time setup (skip if config exists)

Check if `~/.claude/skills/auto-standup/config.json` exists.

**If it does not exist**, run setup now — this is the only time the skill asks questions:

1. Ask: "Which sources should I scrape for your standup? (select all that apply)"
   - GitHub (PRs, commits, issues)
   - Notion (pages, tasks, meeting notes)
   - Slack (messages, threads)
   - Gmail (emails sent/received)

2. Ask: "What is Trinity's Slack user ID? (e.g. U012AB3CD — find it by right-clicking Trinity in Slack → View profile → Copy member ID)"

3. Save both to `~/.claude/skills/auto-standup/config.json`:
   ```json
   {
     "sources": ["github", "notion", "slack", "gmail"],
     "trinity_slack_user_id": "U012AB3CD"
   }
   ```
   Only include sources the user selected.

4. Tell the user: "Config saved. To change settings later, delete `~/.claude/skills/auto-standup/config.json` and run `/auto-standup` again." Then proceed immediately to Step 1.

**If the config exists**, read it silently and proceed to Step 1. Only run source sections whose key appears in `sources`.

---

## Step 1 — Detect my GitHub handle

```bash
gh api user --jq .login
```

Use the result as `<my-handle>` everywhere. If this fails, use `@me` and note `[gh handle unresolved]`.

## Step 2 — Resolve the date window (run `date`, then proceed)

1. Run `date` — this is authoritative, do not guess.
2. `today` = the date `date` reported.
3. `yesterday` = my last working day:
   - Tue–Fri → previous calendar day
   - Mon → last Friday (window covers Fri 00:00 through Mon 00:00, Sat/Sun work included)
   - Sat/Sun → previous calendar day
4. Print the window once (e.g. `yesterday = 2026-04-17 (Fri)`) then proceed immediately.

## Step 3 — Pull proof-of-work (configured sources only)

### GitHub (`"github"`)

1. **Commits I authored**:
   ```bash
   git log --author="$(git config user.name)" --since="<yesterday> 00:00" --until="<today> 00:00" --all --pretty=format:"%h %s (%ar)"
   ```
2. **PRs I authored or updated**:
   ```bash
   gh search prs --author=<my-handle> --updated=">=<yesterday>" \
     --json number,title,url,state,repository,updatedAt
   ```
3. **PRs I reviewed** (substantive comments only, not click-approve):
   ```bash
   gh search prs --reviewed-by=<my-handle> --updated=">=<yesterday>" \
     --json number,title,url,repository,updatedAt
   ```
4. **Issues I closed / opened / commented on**:
   ```bash
   gh search issues --involves=<my-handle> --updated=">=<yesterday>" \
     --json number,title,url,state,repository,updatedAt
   ```
5. **Open issues for Today**:
   ```bash
   gh issue list --assignee=<my-handle> --state=open --json number,title,url
   ```

Extract: Yesterday = merged PRs + closed issues. Today = open PRs + open issues. Blocked = PRs with no review in 24h, issues labelled "blocked" or "waiting". Area = infer from repo names.

### Notion (`"notion"`)

If Notion MCP is not connected, skip and note `[Notion unavailable]`.

1. Search for pages I edited or created yesterday using a last-edited filter.
2. Read the title and brief summary of each result.
3. Extract: Yesterday = pages completed or moved to Done. Today = pages In Progress or dated today. Blocked = pages with a Blocked status. Area = database or project name.

### Slack (`"slack"`)

If Slack MCP is not connected, skip and note `[Slack unavailable]`.

1. Search for messages I sent yesterday.
2. Search for threads I participated in yesterday.
3. Extract: Yesterday = decisions I drove, coordination I completed. Blocked = threads where I asked a question with no reply.

### Gmail (`"gmail"`)

If Gmail MCP is not connected, skip and note `[Gmail unavailable]`.

1. Search `from:me newer_than:1d` for emails I sent.
2. Search `to:me newer_than:1d is:unread` for emails waiting on my response.
3. Extract: Yesterday = important threads I replied to or resolved. Blocked = threads where I'm waiting on someone else.

---

## Step 4 — Infer Area(s) (no asking)

Map repos and Notion databases to: `subnet`, `ai-research`, `platform`. Pick 1–3, comma-separated. Default to `platform` if ambiguous.

## Step 5 — Draft Today (no asking)

Infer from in-progress PRs not yet merged and open assigned issues. If guessing heavily, append `[draft]`.

## Step 6 — Default Blocked to "none" (no asking)

Only include a blocker if explicitly evidenced in a PR description, issue body, Gmail thread, or Slack thread. Otherwise: `none`.

## Step 7 — Present draft and confirm

Show the standup draft in this exact format:

```
standup:
• Area(s): <comma-separated slugs>
• Yesterday: <item> — [repo#N](url), [repo#M](url); <item> — [repo#K](url)
• Today: <item> — [repo#N](url); <item>
• Blocked: <blocker with link, or "none">
```

Then ask exactly: **"Does this look good? Say 'yes' to send to Trinity, or tell me what to change."**

- If the user requests changes, apply them and show the updated draft. Ask again.
- Repeat until the user says "yes" (or any clear confirmation like "send it", "looks good", "go ahead").
- Do not send until you have an explicit yes.

## Step 8 — Send to Trinity

Once confirmed:

1. Read `trinity_slack_user_id` from `~/.claude/skills/auto-standup/config.json`.
2. Open a DM with Trinity using `slack_send_message` to that user ID.
3. Send the standup text exactly as confirmed — no extra commentary, no preamble. Trinity parses the raw text.
4. Confirm to the user: "Sent to Trinity ✓"
5. If the send fails, show the error and say: "You can paste it manually into your Trinity DM."

## Rules

- **One-shot. Never ask questions after setup.** If uncertain, infer and mark `[draft]`.
- **Every PR uses `[repo#N](full-github-url)` syntax.** No bare URLs, no Slack mrkdwn `<url|label>`.
- **Every Yesterday item needs at least one link.** No link = drop the item.
- **Exactly 4 bullets.** Compress with `; ` — do not split into more bullets.
- **One clause per unit of work; list ALL PR refs in that clause.**
- **Verbs reflect state**: `Merged`, `Opened`, `Reviewed`, `Closed`. Not `Shipped` or `Landed` for open work.
- **Monday prefix**: start Yesterday with `Last Fri:` on Mondays.
- **Don't invent work.** No evidence = not included. Incomplete draft is fine.
- **Sources not in config are silently skipped** — do not mention them in output.

## Example output

```
standup:
• Area(s): platform
• Yesterday: Merged SONAR Cloud Alpha infra stack — [psdn-charts#140](https://github.com/PSDN-AI/psdn-charts/pull/140), [infra-aws-eks#180](https://github.com/PSDN-AI/infra-aws-eks/pull/180); opened ArgoCD Apps — [psdn-gitops#297](https://github.com/PSDN-AI/psdn-gitops/pull/297), [psdn-gitops#298](https://github.com/PSDN-AI/psdn-gitops/pull/298)
• Today: Merge ArgoCD Apps — [psdn-gitops#297](https://github.com/PSDN-AI/psdn-gitops/pull/297), [psdn-gitops#298](https://github.com/PSDN-AI/psdn-gitops/pull/298) [draft]
• Blocked: none
```
