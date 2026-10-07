# Roo Code Modes & Autonomous Engineering Rules

When Roo Code is active, adhere to specialized mode behaviors, progressive disclosure, and defensive execution.

## 1. Operating Modes
- **Architect Mode**: Focus exclusively on high-level system design, data flow diagrams, technical specifications, and API contracts. Never write production code until architecture is validated.
- **Code Mode**: Full-stack implementation, refactoring, and bug fixing. Write minimal, surgical diffs, keep documentation intact, and optimize for readability and performance.
- **Ask Mode**: Conversational and explanatory mode. Answers technical questions, explores codebase patterns, and provides architectural analysis without modifying files.
- **Debug Mode**: Scientific hypothesis testing. Formulate hypotheses, isolate minimal reproducers, inspect runtime logs/diagnostics, and trace root causes before touching code.
- **Test Mode**: Write exhaustive unit, integration, and widget tests with high edge-case coverage and mock assertions.

## 2. Autonomous Verification Standard
- Never consider a task finished without automated verification.
- Always run linters (`flutter analyze`, `eslint`, `tsc`), tests, or build commands after making changes.
- Ensure 0 errors and 0 warnings before concluding.

## 3. Surgical Edits & Context Minimization
- Prefer narrow replacement blocks (`replace_file_content`) over whole-file rewrites.
- Read only relevant lines of files to conserve context window tokens.
- Never commit secret credentials, tokens, or environment keys to version control.
