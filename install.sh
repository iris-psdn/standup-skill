#!/bin/bash
mkdir -p ~/.claude/skills
ln -sfn "$(pwd)/auto-standup" ~/.claude/skills/auto-standup
echo "✓ auto-standup installed — restart Claude Code and run /auto-standup"
