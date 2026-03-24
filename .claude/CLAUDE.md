# Global Claude Code Guidelines

## General Principles

- **Minimal changes.** Only change what is necessary to accomplish the task. Do not refactor, add comments, or "improve" unrelated code.
- **No guessing.** If requirements are ambiguous, ask for clarification rather than making assumptions.
- **Check before assuming.** Verify directory structure and file existence before creating or modifying files.

## Planning & Execution

- **Plan before coding.** For complex tasks, invest energy in planning so implementation can be done in a single pass. A good plan avoids issues down the line.
- **Skip planning for one-diff tasks.** If the change can be described in one sentence, go straight to implementation.
- **Re-plan on failure.** When a task derails, stop and re-plan rather than pushing forward blindly.
- **Outcome-based prompts.** Describe the desired outcome and let the implementation follow.
- **Iterate on approach, restart on pollution.** Push for better results rather than accepting mediocre output. But if the conversation is cluttered with failed attempts, start a fresh session with a refined prompt — clean context beats accumulated confusion.
- **Use extended thinking for hard problems.** Say "think hard" or "think harder" to unlock deeper reasoning on complex architectural or debugging tasks.
- **Interview before large features.** For ambiguous or large features, interview me about requirements, edge cases, and tradeoffs before writing any code. Then execute from the resulting spec in a fresh session.

## Context Management

- **One task per session.** Clear context between unrelated tasks. Mixing tasks degrades quality.
- **Use subagents for exploration.** Research in subagents preserves the main context window — thousands of tokens of exploration compress to a concise summary.
- **Scope investigations narrowly.** Open-ended "investigate everything" prompts fill context fast. Be specific about what to look for.
- **After two failed corrections, start fresh.** Context polluted with failed approaches is worse than a clean restart with a better prompt.
- **Use fresh context for reviews.** When reviewing complex changes, a fresh session or subagent catches issues that the writing session's biased context misses.

## Verification

- **Always verify your work.** Use available feedback loops (tests, typechecks, linters, build commands) to confirm changes are correct before finishing. Verification 2-3x the quality of the final result.
- **Typecheck, test, lint — in that order.** Run the fastest checks first to catch errors early: typecheck (fast) → test → lint → PR.
- **Plan verification steps too.** When planning work, explicitly include how you will verify correctness — not just what you will implement.
- **Challenge the output.** After complex changes, critique your own work — look for edge cases, race conditions, or missed requirements before considering the task done.

## Code Quality

- **Match existing style.** Follow the conventions already established in the project (naming, formatting, structure). Do not impose a different style.
- **Preserve existing formatting.** If a file uses tabs, use tabs. If it uses 2-space indent, use 2-space indent. Do not reformat.
- **No premature abstraction.** Write straightforward code. Three similar lines are better than a premature helper function. Introduce abstractions only when there is clear, present duplication.
- **Security first.** MUST NOT introduce command injection, XSS, SQL injection, or other OWASP vulnerabilities. Validate at system boundaries (user input, external APIs), not internal calls.
- **No dead code.** Do not leave commented-out code, unused imports, or placeholder comments like `// removed`. Delete what is not needed.
- **Explain the why.** When the logic is non-obvious, explain *why* a change was made, not just *what* changed.

## Git & Version Control

- **MUST NOT create commits unless explicitly requested.**
- **New commits, not amends.** Always create new commits rather than amending, unless specifically asked to amend.
- **Meaningful messages.** Commit messages should explain *why*, not just *what*.
- **Stage specific files.** Use `git add <file>` rather than `git add .` or `git add -A`.
- **MUST NOT force-push** without explicit approval, especially to main/master.

## Testing

- **Run tests after changes.** When modifying code that has associated tests, run them to verify nothing is broken.
- **Match test style.** Write tests that follow the existing test patterns in the project (framework, naming, structure).
- **Test the behavior, not the implementation.** Focus on inputs, outputs, and observable side effects.

## Communication

- **Surface blockers early.** If something is unclear or blocked, raise it immediately rather than guessing.

## CLAUDE.md as Living Knowledge

- **Learn from corrections.** When corrected, update CLAUDE.md so the same mistake is not repeated.
- **Keep it under 200 lines.** Ruthlessly edit — remove outdated rules, consolidate duplicates, sharpen language.
- **Include build/test/lint commands.** Document the specific commands for typechecking, testing, linting, and formatting so every session can verify its own work.
- **Document antipatterns.** Record specific mistakes and the correct alternative (e.g., "never use `enum`; prefer literal unions") so they are not repeated.
- **Project-level overrides.** Use repo-root CLAUDE.md files for project-specific conventions. More specific files take priority over this global one.
- **Use @import for detailed references.** Keep CLAUDE.md concise and reference external docs inline (e.g., `@docs/api-conventions.md`) for details Claude can load on demand.
- **Use `.claude/rules/` for path-scoped rules.** For larger projects, split rules into focused files that load only when Claude accesses matching paths — more token-efficient than one large file.
- **Use hooks for must-always-happen rules.** If a rule MUST execute every time (auto-format after edits, block writes to migrations), configure it as a hook in settings.json. CLAUDE.md is advisory; hooks are deterministic.
- **CLAUDE.md survives compaction; conversation instructions don't.** Any rule that must persist across long sessions belongs here, not stated verbally in chat.

## File & Project Hygiene

- **Respect .gitignore.** Never commit files that should be ignored (build artifacts, node_modules, .env, credentials).
- **No documentation files unless asked.** Do not create README.md, CHANGELOG.md, or other docs unless explicitly requested.

## Error Handling

- **Don't over-handle errors.** Only add error handling where failures are realistically possible and actionable. Trust internal code and framework guarantees.
- **No retry loops.** If something fails, diagnose the root cause rather than retrying blindly.
- **Fail loudly.** Prefer clear error messages over silent fallbacks that hide problems.

## Dependencies & Tools

- **Use existing dependencies.** Before adding a new library, check if the project already has a dependency that covers the need.
- **Pin versions.** When adding dependencies, use exact versions or lock files rather than floating ranges, unless the project convention is otherwise.
- **Use project tooling.** Respect the project's build system, linter, formatter, and test runner. Do not introduce alternatives.

## Platform Awareness

- **Windows compatibility.** This environment runs Windows with bash shell. Use Unix shell syntax but be mindful of path separators and OS-specific behavior when writing cross-platform code.

## Gotchas

- **Trace type changes through all consumers before proposing them.** When changing a data type (e.g., `float` → `Decimal`, column type `REAL` → `TEXT`), verify every downstream use site — SQL operators (`SUM`, `>=`), serialization (`model_dump(mode="json")`), formatters, tests. The `Decimal`/`TEXT` change introduced three bugs: broken SQL aggregation, broken SQL comparisons (lexicographic on TEXT), and silent Decimal→float conversion in Pydantic's JSON mode. A simpler type that works everywhere beats a "correct" type that breaks at every boundary.
- **Verify constructor defaults match all call sites.** When a constructor parameter defaults to `None` (e.g., `db_path=None` → in-memory DB), check every caller. If the CLI also defaults to `None`, the "test-only" code path silently becomes the production path. Defaults must be safe for the most common call site, not the edge case.
- **When reviewing a design document, verify the fix doesn't reintroduce the problem it claims to solve.** The dedup hash was flagged as body-only in the analysis of the current code, then the redesign's `_hash_sms_body()` repeated the exact same weakness. Cross-check each fix against the original problem statement.
