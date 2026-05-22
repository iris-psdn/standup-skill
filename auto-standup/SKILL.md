---
name: auto-standup
description: Draft my daily Trinity standup in one pass by pulling GitHub, Notion, Slack, and Gmail activity — no questions asked, output ready to paste.
user-invocable: true
---

You are helping me write my daily standup report. Produce a complete draft in ONE pass — do **not** ask me questions, do **not** pause for confirmation. A draft that's 80% right and I can edit in 30 seconds is far more useful than a perfect one that needs 5 minutes of back-and-forth. The output must match the format Trinity expects in our Slack standup thread.

## Step 0 — Detect my GitHub handle (run once, then proceed)

Run this to find out who I am:

```bash
gh api user --jq .login
```

Use the result as `<my-handle>` everywhere in this skill. Do not hardcode a name. If the command fails (not authenticated), use `@me` for all `gh` commands and note `[gh handle unresolved]` in the output.

## Step 1 — Resolve the date window (run `date`, then proceed)

1. **Do not guess the date.** Run `date` in the shell to get the current local date and day-of-week. This is authoritative — do not infer from conversation context or your training data.
2. `today` = the date `date` just reported, interpreted in **my local timezone**. Our engineers are in **Palo Alto (PT)**, **India (IST)**, or **China (CST)** — use whatever `date` shows on my machine, do not assume a fixed timezone.
3. `yesterday` = my last working day in that same local timezone:
   - If today is **Tue–Fri** → yesterday = the previous calendar day.
   - If today is **Mon** → yesterday = **last Friday**. The lookback window covers Fri 00:00 through Mon 00:00, so any Sat/Sun work is still included.
   - If today is **Sat/Sun** → yesterday = the previous calendar day.
4. Print the window once (e.g. `yesterday = 2026-04-17 (Fri)`; on Mondays `yesterday = 2026-04-17 (last Friday); window includes Sat/Sun`) so I can eyeball it, then **proceed immediately to Step 2**. Do NOT wait for confirmation.

## Step 2 — Pull proof-of-work for yesterday

### Github (MCP)
Run these silently using `<my-handle>` resolved in Step 0.

1. **Commits I authored** (current repo only — `gh search prs` below covers cross-repo):
   ```
   git log --author="$(git config user.name)" --since="<yesterday> 00:00" --until="<today> 00:00" --all --pretty=format:"%h %s (%ar)"
   ```
2. **PRs I authored or updated**:
   ```
   gh search prs --author=<my-handle> --updated=">=<yesterday>" \
     --json number,title,url,state,repository,updatedAt
   ```
3. **PRs I reviewed (substantive comments only, not click-approve)**:
   ```
   gh search prs --reviewed-by=<my-handle> --updated=">=<yesterday>" \
     --json number,title,url,repository,updatedAt
   ```
4. **Issues I closed / opened / commented on**:
   ```
   gh search issues --involves=<my-handle> --updated=">=<yesterday>" \
     --json number,title,url,state,repository,updatedAt
   ```

### Notion (MCP)

If Notion MCP is not connected, skip and note `[Notion unavailable]`.

1. Search for pages I edited or created yesterday:
   - Use the Notion search tool with a last-edited filter for yesterday's date range.
2. For each result, read the page title and a brief summary of changes.
3. Look specifically for: meeting notes, design decisions, project updates, task completions.

### Slack (MCP)

If Slack MCP is not connected, skip and note `[Slack unavailable]`.

1. Search for messages I sent yesterday.
2. Search for threads I participated in yesterday.
3. Look specifically for: decisions I was part of, action items assigned to me, cross-team coordination I drove, anything I said I would follow up on (potential Today items).

### Gmail (MCP)

If Gmail MCP is not connected, skip and note `[Gmail unavailable]`.

1. Search for emails I sent or received yesterday involving project progress, decisions, or approvals.
2. Look specifically for: unanswered threads where I am waiting on someone else → these are potential blockers.
3. Do not include internal emails that are already covered by GitHub or Slack.

**Other work** (Linear, Figma, customer calls) is **out of scope for this draft** — I will add those manually after. Do NOT ask me about them.

## Step 3 — Infer Area(s) (no asking)

Map the repos touched to one of the known team areas: `subnet`, `ai-research`, `platform`. Pick 1–3, comma-separated. Do NOT ask me to confirm — commit to your best inference. If genuinely ambiguous, default to `platform`.

## Step 4 — Draft "Today" (no asking)

Do NOT ask me "what's on your plate today?". Infer from:
- In-progress PRs from Step 2 that aren't merged yet.
- Open issues assigned to me: `gh issue list --assignee=<my-handle> --state=open --json number,title,url`.

Write a realistic continuation of yesterday's work (e.g. "Merge SONAR #26/#27/#28; continue ArgoCD Apps #297/#298"). If you had to guess heavily, append ` [draft]` to the Today field so I know to double-check.

## Step 5 — Default Blocked to "none" (no asking)

Do NOT ask me "any blockers?". Default to `none`. Only include a blocker if it is **explicitly** evidenced in:
- A PR description, issue body, or review comment from Step 2 — cite the link
- A Gmail thread where I am waiting on an unanswered reply — cite the subject
- A Slack thread where I flagged something as stuck or waiting

## Step 6 — Output (one pass, no follow-up)

Produce **exactly** this block, with no preamble, no trailing questions, and no "let me know if..." — just the block, ready to paste into the Trinity standup thread. **Every PR reference MUST use standard Markdown link syntax `[repo#N](https://github.com/PSDN-AI/repo/pull/N)`** (e.g. `[SONAR#23](https://github.com/PSDN-AI/SONAR/pull/23)`). Slack (with the one-time "Format messages with markup" preference enabled — see Notes) renders these as compact clickable short labels. Do NOT use bare URLs (visually noisy) or Slack's `<URL|label>` mrkdwn (that's API-only, unreliable on paste).

```
standup:
• Area(s): <comma-separated project slugs>
• Yesterday: <work item 1> — [<repo>#<N>](https://github.com/PSDN-AI/<repo>/pull/<N>), [<repo>#<M>](https://github.com/PSDN-AI/<repo>/pull/<M>); <work item 2> — [<repo>#<K>](https://github.com/PSDN-AI/<repo>/pull/<K>)
• Today: <plan item 1> — [<repo>#<N>](https://github.com/PSDN-AI/<repo>/pull/<N>); <plan item 2>
• Blocked: <blocker with [<repo>#<N>](https://github.com/PSDN-AI/<repo>/pull/<N>) link if applicable, or "none">
```

## Rules

- **One-shot. Never ask questions.** Produce the complete block in one pass. If something is uncertain, make a reasonable inference and mark the field with `[draft]` — don't pause to ask.
- **Every PR reference uses standard Markdown link syntax `[repo#N](full-github-url)`** (e.g. `[SONAR#23](https://github.com/PSDN-AI/SONAR/pull/23)`). When the engineer has Slack's "Format messages with markup" preference enabled (one-time setup), this renders as a clickable short label like `SONAR#23`. Do NOT use bare URLs (noisy when many), do NOT use Slack mrkdwn `<URL|label>` (API-only — Rich Text editor breaks it on paste), do NOT use plain `repo#N` text (Slack's GitHub App does not auto-link arbitrary refs, only full URLs).
- **Every Yesterday work item needs at least one such link.** If you have no linkable evidence, drop the item — do not pad.
- **Compress Yesterday / Today items with `; ` (semicolon + space)**. Do NOT split into multiple bullets — Trinity's schema is exactly 4 bullets.
- **One clause per logical unit of work**, not per commit. **Within each clause, list ALL PR refs** as `[repo#N](URL)` links — not just one representative. Example clause: `Merged SONAR Cloud Alpha infra stack — [psdn-charts#140](https://github.com/PSDN-AI/psdn-charts/pull/140), [psdn-charts#141](https://github.com/PSDN-AI/psdn-charts/pull/141), [infra-aws-eks#180](https://github.com/PSDN-AI/infra-aws-eks/pull/180), [psdn-console#171](https://github.com/PSDN-AI/psdn-console/pull/171), [SONAR#21](https://github.com/PSDN-AI/SONAR/pull/21)`.
- **Preserve state in verbs.** Use `Merged`, `Opened`, `Reviewed`, `Closed` — do NOT say `Shipped` or `Landed` for work that is still open. Mixed clusters: `Merged X, opened Y`.
- **Yesterday / Today may wrap across Slack lines.** Real workdays don't fit in 2 lines; compress prose, not refs — the goal is faithful coverage of the day.
- **Don't count review-only approvals.** A review counts only if the engineer left substantive comments.
- **Don't invent work.** If you can't find evidence in git/gh, don't include it. It's fine for the draft to be incomplete — I'll fill gaps manually.
- **Don't leak internal URLs** that aren't already in GitHub / Notion.
- **Area(s): 1–3, comma-separated, from the known set** (`subnet`, `ai-research`, `platform`). Default `platform` if ambiguous.
- **When today is Monday, prefix the Yesterday content with `Last Fri:`** so readers of the standup know the window covers Friday + any weekend work. Skip this prefix on Tue–Fri.

## Example output (for reference — don't copy into real standups)

```
standup:
• Area(s): platform
• Yesterday: Merged SONAR Cloud Alpha infra stack (Helm chart, SM bootstrap, ECR/OIDC, R2 lifecycle, CI green) — [psdn-charts#140](https://github.com/PSDN-AI/psdn-charts/pull/140), [psdn-charts#141](https://github.com/PSDN-AI/psdn-charts/pull/141), [infra-aws-eks#180](https://github.com/PSDN-AI/infra-aws-eks/pull/180), [psdn-console#171](https://github.com/PSDN-AI/psdn-console/pull/171), [SONAR#21](https://github.com/PSDN-AI/SONAR/pull/21); opened service image + ArgoCD Apps for dev/stag — [SONAR#26](https://github.com/PSDN-AI/SONAR/pull/26), [SONAR#27](https://github.com/PSDN-AI/SONAR/pull/27), [SONAR#28](https://github.com/PSDN-AI/SONAR/pull/28), [psdn-gitops#297](https://github.com/PSDN-AI/psdn-gitops/pull/297), [psdn-gitops#298](https://github.com/PSDN-AI/psdn-gitops/pull/298); merged inter-service bearer auth (SONAR↔Hono server) — [SONAR#23](https://github.com/PSDN-AI/SONAR/pull/23), opened client — [psdn-console#167](https://github.com/PSDN-AI/psdn-console/pull/167); scaffolded weekly status templates for 2026-04-20 — [tpm-agent#49](https://github.com/PSDN-AI/tpm-agent/pull/49) merged, [tpm-agent#50](https://github.com/PSDN-AI/tpm-agent/pull/50), [tpm-agent#51](https://github.com/PSDN-AI/tpm-agent/pull/51), [tpm-agent#52](https://github.com/PSDN-AI/tpm-agent/pull/52) opened
• Today: Merge SONAR Dockerfile + GHA — [SONAR#26](https://github.com/PSDN-AI/SONAR/pull/26), [SONAR#27](https://github.com/PSDN-AI/SONAR/pull/27), [SONAR#28](https://github.com/PSDN-AI/SONAR/pull/28); drive ArgoCD Apps — [psdn-gitops#297](https://github.com/PSDN-AI/psdn-gitops/pull/297), [psdn-gitops#298](https://github.com/PSDN-AI/psdn-gitops/pull/298); land auth client — [psdn-console#167](https://github.com/PSDN-AI/psdn-console/pull/167); land weekly templates — [tpm-agent#50](https://github.com/PSDN-AI/tpm-agent/pull/50), [tpm-agent#51](https://github.com/PSDN-AI/tpm-agent/pull/51), [tpm-agent#52](https://github.com/PSDN-AI/tpm-agent/pull/52) [draft]
• Blocked: none
```
