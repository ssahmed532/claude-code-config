# /repo-audit — Deep Repository Security & Hygiene Audit

Perform a comprehensive security and hygiene audit of a git repository using parallel sub-agents. This skill scans for secrets, PII, sensitive files, git history leaks, .gitignore effectiveness, and common repo hygiene issues.

## Arguments

- Optional: a path to the repository to audit (e.g., `/repo-audit D:/wa_git/some-repo`)
- If no path is provided, audit the git repository in the current working directory

## Execution

### Step 1: Validate the target

Determine the target repository path:
- If an argument was provided, use that path
- Otherwise, use the current working directory

Verify the target is a valid git repository by running `git -C "<repo_path>" rev-parse --git-dir`. If it fails, stop and tell the user this is not a git repo.

Store the resolved absolute repo path as `REPO_PATH` for all subsequent steps.

### Step 2: Launch 5 parallel sub-agents

Launch ALL 5 of the following sub-agents simultaneously using the Agent tool. Every agent receives the `REPO_PATH` value.

---

**Agent 1: Secrets & Credentials Scan**

> Perform a thorough secrets scan of the git repository at `REPO_PATH`.
>
> 1. List all committed files: `git -C "REPO_PATH" ls-files`
> 2. Read every committed file
> 3. Search for:
>    - API keys and tokens (patterns: `sk-`, `gho_`, `ghp_`, `glpat-`, `xoxb-`, `xoxp-`, `AKIA`, `Bearer`, `token`, `api_key`, `apikey`, `secret`, `password`)
>    - Private keys (`BEGIN.*PRIVATE KEY`, `BEGIN.*RSA`, `BEGIN.*DSA`, `BEGIN.*EC`)
>    - Connection strings (database URIs with embedded credentials)
>    - Base64-encoded blobs that look like credentials (high entropy strings > 40 chars)
>    - Hardcoded URLs with embedded usernames/passwords
>    - .env file contents or similar credential stores
> 4. Also scan git history: `git -C "REPO_PATH" log --all -p` for any secrets that were committed then removed
>
> For each finding, report: file path, line number, the pattern matched, and classify as CRITICAL/WARNING/INFO.
> If nothing found, explicitly state "No secrets or credentials detected."

---

**Agent 2: PII & Sensitive Data Scan**

> Perform a thorough PII scan of the git repository at `REPO_PATH`.
>
> 1. List all committed files: `git -C "REPO_PATH" ls-files`
> 2. Read every committed file
> 3. Search for:
>    - Real names (first + last name patterns, not generic usernames)
>    - Email addresses (especially personal ones, not noreply@)
>    - Phone numbers (any format: +1-xxx, (xxx), etc.)
>    - Physical addresses or specific locations
>    - Account numbers (bank, investment, brokerage patterns)
>    - Dollar amounts or financial figures that look like real personal data
>    - Social Security Numbers or national ID patterns (xxx-xx-xxxx, etc.)
>    - IP addresses (especially internal/private ranges)
>    - File paths containing real usernames or personal directory names
>    - Real company or organization names that reveal private associations
> 4. Check git author metadata: `git -C "REPO_PATH" log --format="%an <%ae>" | sort -u`
> 5. Check filenames themselves for PII patterns
>
> For each finding, report: file path, line number, what was found, and classify as CRITICAL/WARNING/INFO.
> CRITICAL = must fix before public. WARNING = review needed. INFO = noted but likely acceptable.

---

**Agent 3: Gitignore Effectiveness Verification**

> Verify the .gitignore effectiveness for the git repository at `REPO_PATH`.
>
> 1. Read the .gitignore file(s): check repo root and any nested .gitignore files
> 2. List ALL committed files: `git -C "REPO_PATH" ls-files`
> 3. List ALL files on disk: `find "REPO_PATH" -type f -not -path '*/.git/*'`
> 4. Compare and check for:
>    - Files on disk that SHOULD be gitignored but are not (common: .env, node_modules/, __pycache__/, .DS_Store, Thumbs.db, *.pyc, credentials.*, secrets.*)
>    - Committed files that look sensitive (session data, cache files, debug logs, credential files)
>    - Missing .gitignore entries for the project type (e.g., Python project without __pycache__ exclusion)
> 5. If .gitignore does not exist at all, flag this as a WARNING
> 6. Check for force-added files in gitignored directories: `git -C "REPO_PATH" ls-files -i --exclude-standard`
>
> Report as a pass/fail checklist. For each FAIL, include the file path and recommended .gitignore rule.

---

**Agent 4: Git History Audit**

> Audit the full git history of the repository at `REPO_PATH`.
>
> 1. `git -C "REPO_PATH" log --all --oneline` — count and list all commits
> 2. `git -C "REPO_PATH" log --all --diff-filter=D --summary` — find files deleted from history
> 3. `git -C "REPO_PATH" log --all -p` — full diff, scan for sensitive patterns (secrets, PII, credentials)
> 4. `git -C "REPO_PATH" reflog` — check for amended or reset commits that could hide content
> 5. `git -C "REPO_PATH" stash list` — check for stashed changes with potential secrets
> 6. `git -C "REPO_PATH" branch -a` — list all branches, flag any unexpected ones
> 7. `git -C "REPO_PATH" log --all --format="%H %s" --diff-filter=R --summary` — check for renamed files that might have been sensitive
>
> Flag:
> - Files committed then deleted (still recoverable from history)
> - Commits that were amended (original content in reflog)
> - Sensitive content in any historical diff
> - Unexpected branches with divergent content
>
> Report each finding with commit hash, file path, and classification.

---

**Agent 5: Repository Hygiene Check**

> Check repository hygiene for the git repository at `REPO_PATH`.
>
> 1. List all committed files: `git -C "REPO_PATH" ls-files`
> 2. Check for large files: `git -C "REPO_PATH" ls-files -z | xargs -0 -I{} git -C "REPO_PATH" ls-files -s "{}" | sort -k3 -n -r` or use `find` to check sizes of tracked files
> 3. Check for:
>    - **Large binaries** (>1MB): images, videos, archives, compiled binaries, database files committed to the repo
>    - **Missing LICENSE file**: no LICENSE or LICENSE.md at the repo root
>    - **Missing .gitignore**: no .gitignore at the repo root
>    - **Missing README**: no README.md or README at the repo root
>    - **Build artifacts committed**: node_modules/, dist/, build/, __pycache__/, .class files, .o files, .dll, .exe
>    - **IDE/editor files committed**: .vscode/, .idea/, *.swp, *.swo, .project, .classpath
>    - **OS-generated files committed**: .DS_Store, Thumbs.db, desktop.ini
>    - **Lock files without package file**: package-lock.json without package.json, uv.lock without pyproject.toml, etc.
>    - **Empty directories or placeholder files** that serve no purpose
>    - **Merge conflict markers** (`<<<<<<<`, `=======`, `>>>>>>>`) left in committed files
>
> Report each finding with file path, size (if relevant), and classify as CRITICAL/WARNING/INFO.

---

### Step 3: Consolidate and present findings

After all 5 agents complete:

1. Combine all findings into a unified summary table grouped by severity (CRITICAL first, then WARNING, then INFO)
2. Display the summary in the conversation using this format:

```
## Repository Security & Hygiene Audit — <repo_name>

### Overall: [CLEAN / ISSUES FOUND]

| # | Severity | Category | File | Finding |
|---|----------|----------|------|---------|
| 1 | CRITICAL | Secrets  | path:line | Description |
| ... | ... | ... | ... | ... |

### Agent Results
- Secrets scan: CLEAN / X findings
- PII scan: CLEAN / X findings
- Gitignore check: X/Y checks passed
- Git history: CLEAN / X findings
- Repo hygiene: CLEAN / X findings
```

3. Write the full detailed report to `REPO_PATH/SECURITY-AUDIT.md` with all findings from every agent, including the per-agent details
4. Add `SECURITY-AUDIT.md` to the repo's `.gitignore` if not already present (append it, do not overwrite existing content)
5. If the .gitignore was modified, inform the user

### Important Notes

- Do NOT create any commits. Only write the report file and update .gitignore.
- Do NOT push anything to remote.
- If the repo has a very large history (>500 commits), limit the `git log -p` scan to the last 100 commits and note this limitation in the report.
- If any agent encounters an error, report the error in the summary rather than failing silently.
