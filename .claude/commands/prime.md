---
allowed-tools: Bash, Read
description: Load context for a new agent session by analyzing codebase structure, documentation and CLAUDE.md
---

# Prime

Run the commands under the `Execute` section to gather information about the project, and then review the files listed under `Read` to understand the project's purpose and functionality. Use context7 MCP to get the latest GitHub Actions documentation for reference, then `Report` your findings.

## Execute
- `git ls-files`
- `resolve-library-id`
- `get-library-docs`

## Read
- .claude/dev-docs/*
- .github/scripts/*
- .github/workflows/*
- .github/subrepo-config.json
- CLAUDE.md

## Report

- Provide a summary of your understanding of the project