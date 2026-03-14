---
name: subagent-worker
description: Split complex requests into independent subagent tasks, run isolated validation passes, and merge verified outputs. Use when users ask for subagent execution, independent review, or comparison-based verification.
---

# Subagent Worker

## Overview

Split a request into independent subagent tasks, run isolated passes, and merge results with explicit evidence.
Keep each pass task-local so quality does not depend on leaked context.

## Workflow

1. Split the request into 2-4 independent tasks.
2. Define one concrete output and acceptance criteria for each task.
3. Write a minimal prompt for each pass with only required artifacts and constraints.
4. Run each pass independently in a fresh context when possible.
5. Compare outputs, resolve conflicts, and run final verification before reporting.

## Prompt Template

```text
Use $subagent-worker at <path> to complete this task.

Goal:
<one clear objective>

Inputs:
<files/logs/notes needed for this task only>

Constraints:
- <constraint 1>
- <constraint 2>

Output:
- <deliverable format>
- <validation evidence, such as diff/test/log>
```

## Guardrails

- Avoid giving expected answers, suspected root causes, or intended fixes to subagents unless required.
- Prefer raw artifacts (diffs, logs, test outputs) over narrative-only conclusions.
- Ask the user before long-running, destructive, or production-impacting actions.
- If independent passes disagree, run one extra pass and document the tie-break rule.
