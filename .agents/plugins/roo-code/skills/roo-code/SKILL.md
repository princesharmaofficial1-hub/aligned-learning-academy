---
name: roo-code
description: Multi-mode autonomous engineering engine inspired by Roo Code (Architect, Code, Ask, Debug, Test), with rigorous plan execution and self-healing terminal loops.
---

# Roo Code Autonomous Workflow Skill

Use this skill to execute complex multi-step engineering tasks with Roo Code's signature precision, mode switching, and disciplined verification.

## 1. Mode Selection
Identify the appropriate mode based on the user's prompt:
- **Architect Mode**: System architecture, schema design, technology selection, module boundaries.
- **Code Mode**: Direct coding, refactoring, feature implementation, and optimization.
- **Ask Mode**: Explanations, code review, architectural walkthroughs, and queries.
- **Debug Mode**: Analyzing stack traces, diagnosing test/build failures, fixing elusive race conditions.
- **Test Mode**: Writing unit tests, widget tests, regression tests, and mocking dependencies.

## 2. Autonomous Task Execution Loop
1. **Analyze Requirements**: Parse exact requirements, identify edge cases, and locate affected files.
2. **Context Inspection**: Inspect target files using line-bounded ranges (`view_file`).
3. **Execution Plan**: Outline clear step-by-step actions before modifying state.
4. **Defensive Modification**: Perform focused, non-breaking edits using `replace_file_content` or `multi_replace_file_content`.
5. **Self-Healing Verification**: Run project analyzers, linters, or build commands (`flutter analyze`, `npm test`).
6. **Iterate & Rectify**: If errors occur, diagnose the failure immediately, apply surgical fixes, and re-verify until 100% clean.
