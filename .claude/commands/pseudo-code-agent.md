---
allowed-tools: Read
description: Automatically create a section-focused pseudo-code generation agent based on the current project's CLAUDE.md specifications
---

# Build Section-Focused Pseudo-Code Agent

This command automatically reads the current project's CLAUDE.md file and creates a tailored section-focused pseudo-code generation agent using the meta-agent.

## Read Project Context

First, read CLAUDE.md to understand the current project:

- CLAUDE.md

## Execute

Based on the project context from CLAUDE.md, invoke the meta-agent with the appropriate specifications:

`@agent-meta-agent "Create a section-focused pseudo-code generation agent that analyzes specific parts of this project's codebase and generates clear, concise pseudo-code documentation. The agent should:

- Focus on individual sections (files, modules, components, workflows) rather than the entire codebase
- Generate clear, short, objective pseudo-code for targeted areas
- Read only relevant files for the current analysis target
- Maintain context quality by limiting scope to manageable sections
- Understand the project architecture and technology stack as defined in CLAUDE.md
- Identify dependencies and interfaces between sections
- Provide section-specific insights and documentation

The agent should be tailored to this project's specific:
- Technology stack and frameworks
- Architecture patterns
- Domain context and requirements
- Common code organization patterns

Target section types should include the most relevant code units for this project type (e.g., API endpoints, components, workflows, modules, scripts, etc.)."`

### Example Usage

Simply run the command:
`/pseudo-code-agent`

The command will automatically:
1. Read CLAUDE.md to understand the current project context
2. Extract key technologies, architecture, and domain information
3. Generate the appropriate meta-agent prompt based on the project specifications
4. Create a section-focused pseudo-code agent tailored to this specific project

## Usage Pattern

Once the agent is created, use it by specifying target sections:
1. **Target a specific section**: "Analyze the user authentication module in `/src/auth/`"
2. **Focus on single workflows**: "Generate pseudo-code for the deployment workflow in `.github/workflows/deploy.yml`"
3. **Analyze individual components**: "Document the shopping cart component in `/components/Cart.tsx`"
4. **Build incrementally**: Create comprehensive documentation by analyzing one section at a time