# standup-skill

A Claude Code skill that drafts your daily Trinity standup in one pass by pulling activity from GitHub, Notion, Slack, and Gmail.

## What it does

Run `/auto-standup` in Claude Code and it will:

1. Detect who you are via `gh api user`
2. Pull your GitHub PRs, commits, and issues from yesterday
3. Pull Notion pages you edited
4. Pull Slack messages and threads you participated in
5. Pull relevant Gmail threads
6. Draft a standup in Trinity's format, ready to paste into Slack

Output looks like:

```
standup:
• Area(s): platform
• Yesterday: Merged auth refactor — [repo#42](https://github.com/PSDN-AI/repo/pull/42); opened API cleanup — [repo#43](https://github.com/PSDN-AI/repo/pull/43)
• Today: Land API cleanup — [repo#43](https://github.com/PSDN-AI/repo/pull/43)
• Blocked: none
```

## Requirements

- [Claude Code](https://claude.ai/code)
- `gh` CLI authenticated (`gh auth login`)
- Notion, Slack, and Gmail MCP servers connected in Claude Code

## Install

```bash
git clone https://github.com/iris-psdn/standup-skill
cd standup-skill
chmod +x install.sh
./install.sh
```

Then restart Claude Code and type `/auto-standup`.
