# Global Claude Code Guidelines

## General Principles

- **Read before writing.** Always read relevant files before modifying them. Understand existing patterns, conventions, and architecture first.
- **Minimal changes.** Only change what is necessary to accomplish the task. Do not refactor, add comments, or "improve" unrelated code.
- **Prefer editing over creating.** Modify existing files rather than creating new ones unless a new file is clearly needed.
- **No guessing.** If requirements are ambiguous, ask for clarification rather than making assumptions.

## Planning & Execution

- **Plan before coding.** For complex tasks, invest energy in planning so implementation can be done in a single pass. A good plan avoids issues down the line.
- **Re-plan on failure.** When a task derails, stop and re-plan rather than pushing forward blindly.
- **Outcome-based prompts.** Prefer "fix the failing tests" over prescriptive step-by-step instructions. Describe the desired outcome and let the implementation follow.
- **Iterate, don't restart.** Push for better results on mediocre output rather than starting over. Challenge yourself to find the elegant solution.

## Verification

- **Always verify your work.** Use available feedback loops (tests, typechecks, linters, build commands) to confirm changes are correct before finishing. Verification 2-3x the quality of the final result.
- **Typecheck, test, lint — in that order.** Run the fastest checks first to catch errors early: typecheck (fast) → test → lint → PR.
- **Plan verification steps too.** When planning work, explicitly include how you will verify correctness — not just what you will implement.

## Code Quality

- **Match existing style.** Follow the conventions already established in the project (naming, formatting, structure). Do not impose a different style.
- **No premature abstraction.** Write straightforward code. Three similar lines are better than a premature helper function. Introduce abstractions only when there is clear, present duplication.
- **Security first.** Never introduce command injection, XSS, SQL injection, or other OWASP vulnerabilities. Validate at system boundaries (user input, external APIs), not internal calls.
- **No dead code.** Do not leave commented-out code, unused imports, or placeholder comments like `// removed`. Delete what is not needed.
- **Explain the why.** When the logic is non-obvious, explain *why* a change was made, not just *what* changed.

## Git & Version Control

- **Commit only when asked.** Do not create commits unless explicitly requested.
- **New commits, not amends.** Always create new commits rather than amending, unless specifically asked to amend.
- **Meaningful messages.** Commit messages should explain *why*, not just *what*.
- **Stage specific files.** Use `git add <file>` rather than `git add .` or `git add -A` to avoid accidentally committing sensitive files.
- **No force-push without confirmation.** Never force-push, especially to main/master, without explicit approval.

## Testing

- **Run tests after changes.** When modifying code that has associated tests, run them to verify nothing is broken.
- **Match test style.** Write tests that follow the existing test patterns in the project (framework, naming, structure).
- **Test the behavior, not the implementation.** Focus on inputs, outputs, and observable side effects.

## Communication

- **Be concise.** Lead with the answer or action. Skip preamble and filler.
- **No trailing summaries.** Do not restate what was just done — the diff speaks for itself.
- **Surface blockers early.** If something is unclear or blocked, raise it immediately rather than guessing.

## CLAUDE.md as Living Knowledge

- **Learn from corrections.** When corrected, update CLAUDE.md so the same mistake is not repeated. Claude is effective at writing rules for itself.
- **Keep it under 200 lines.** A concise, focused CLAUDE.md is more effective than an exhaustive one. Ruthlessly edit — remove outdated rules, consolidate duplicates, sharpen language.
- **Include build/test/lint commands.** Document the specific commands for typechecking, testing, linting, and formatting so every session can verify its own work.
- **Document antipatterns.** Record specific mistakes and the correct alternative (e.g., "never use `enum`; prefer literal unions") so they are not repeated.
- **Project-level overrides.** Use repo-root CLAUDE.md files for project-specific conventions. More specific files take priority over this global one.

## File & Project Hygiene

- **Respect .gitignore.** Never commit files that should be ignored (build artifacts, node_modules, .env, credentials).
- **No documentation files unless asked.** Do not create README.md, CHANGELOG.md, or other docs unless explicitly requested.
- **Preserve existing formatting.** If a file uses tabs, use tabs. If it uses 2-space indent, use 2-space indent. Do not reformat.

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
- **Check before assuming.** Verify directory structure and file existence before creating or modifying files.
