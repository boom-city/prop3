---
allowed-tools: firecrawl_search, firecrawl_scrape, firecrawl_map, Read, Write
description: Generate CLAUDE.md files following official Anthropic best practices
---

# CLAUDE.md Generator

Create a comprehensive CLAUDE.md file for Claude Code by analyzing the folder specified in {ARGUMENTS} and incorporating the latest official best practices from Anthropic's documentation.

**Usage**: `/claude-builder @folder/path` or `/claude-builder folder/path`

## Workflow

### 1. Research Current Best Practices
First, search for the most up-to-date CLAUDE.md best practices:
- Use `firecrawl_search` to find latest Anthropic documentation on CLAUDE.md creation
- Query: "CLAUDE.md file creation best practices Anthropic official documentation 2024 2025"
- Scrape key documentation pages with `firecrawl_scrape` for detailed guidelines

### 2. Analyze Project Structure
- Read the folder specified in {ARGUMENTS} recursively to understand:
  - Tech stack and frameworks used
  - Project architecture and key directories
  - Existing code patterns and conventions
  - Build/test/deployment scripts
  - Configuration files and dependencies

### 3. Generate CLAUDE.md Following Best Practices

Create a CLAUDE.md file with these sections (based on official Anthropic guidelines):

#### Essential Sections:
```markdown
# Project Overview
- Brief description of the project
- Main purpose and functionality

# Tech Stack
- Framework: [detected framework and version]
- Language: [primary language and version]
- Key dependencies: [major libraries/tools]

# Project Structure
- src/: [describe main source directory]
- [other key directories]: [their purposes]

# Commands
- Build: [detected build command]
- Test: [detected test command]
- Development: [detected dev server command]
- Lint/Format: [detected linting commands]

# Code Style & Conventions
- [Detected patterns from codebase analysis]
- Import/export preferences
- Naming conventions
- File organization patterns

# Workflow Guidelines
- Branch naming conventions (if detectable)
- Commit message format (if detectable)
- Testing requirements

# CRITICAL REQUIREMENTS - MUST BE FOLLOWED ALWAYS
- **MANDATORY**: Document any project-specific quirks or requirements that could break functionality
- **MANDATORY**: Include performance considerations and constraints that must be respected
- **MANDATORY**: Document security considerations and requirements that cannot be compromised
- **MANDATORY**: Highlight any "DO NOT" rules or dangerous operations to avoid
- **MANDATORY**: Note any legacy code or deprecated patterns that should not be modified
```

## Best Practices to Follow

### Content Guidelines:
- **Be concise and actionable** - Every instruction should be specific and necessary
- **Use bullet points** instead of long paragraphs
- **Focus on project-specific context** that Claude needs to know
- **Avoid redundant information** - don't explain what's obvious from folder names
- **Include only globally applicable processes** that every developer should know

### Structure Guidelines:
- Use clear Markdown headings for organization
- Group related information together  
- Prioritize most important information first
- Keep token usage minimal but comprehensive

### Content Priorities:
1. **Critical commands** (build, test, dev server)
2. **Code style rules** specific to this project
3. **Project architecture** and key files/directories
4. **Workflow processes** (testing, linting, deployment)
5. **Project-specific conventions** and gotchas

## Output Format

Generate a complete CLAUDE.md file that:
- Follows the official Anthropic format recommendations
- Is tailored to the specific project found in the folder path provided in {ARGUMENTS}
- Includes only essential, actionable information
- Uses concise, clear language optimized for AI consumption
- Respects token budget while providing necessary context

The output should be ready to save as `CLAUDE.md` in the target project's root directory (the folder specified in {ARGUMENTS}).