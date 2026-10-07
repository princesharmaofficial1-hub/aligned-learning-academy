---
name: roo-debugger
description: Roo Code Debug Mode for scientific root-cause isolation, stack trace decoding, memory leak diagnostics, and automated verification.
---

# Roo Code Debug Mode

Rigorous, hypothesis-driven debugging workflow.

## 4-Step Scientific Debugging Method
1. **Observe & Reproduce**: Capture exact error outputs, logs, exit codes, and reproduction conditions.
2. **Formulate Hypotheses**: Brainstorm candidate causes based on runtime constraints (e.g. cross-drive file paths, unmanaged timers, missing proguard rules, type mismatches).
3. **Isolate**: Test each hypothesis with targeted evidence collection before making code modifications.
4. **Fix & Verify**: Apply minimal fix and verify against the original failure to confirm resolution with zero regressions.
