# Reconstructed Prompt: Claude Code `/insights` Report Generation

## Overview

The `/insights` feature operates as a **two-phase pipeline**:

1. **Phase 1 — Per-Session Facet Extraction**: Each session's conversation is analyzed individually by an LLM to produce a structured "facet" JSON file.
2. **Phase 2 — Cross-Session Aggregation & Report Synthesis**: All facet JSONs + session metadata are fed to a second LLM call that synthesizes the full insights report.

Both phases likely use Claude as the underlying model. The session metadata (tool counts, timestamps, token usage, etc.) is collected deterministically by the CLI itself — no LLM needed. The facets are the LLM's qualitative judgment layer on top of that quantitative data.

---

## Phase 1: Per-Session Facet Extraction Prompt

This prompt is called once per session, with the session's full conversation transcript as context.

```
You are analyzing a Claude Code session transcript to extract structured metadata about the session. Analyze the conversation between the user and Claude and produce a JSON object with the following fields:

### Required Fields

- **underlying_goal** (string): A one-sentence description of what the user was ultimately trying to accomplish across the entire session. Describe the high-level objective, not individual steps.

- **goal_categories** (object): Categorize the types of tasks requested in the session. Keys are category names (snake_case), values are counts of how many distinct requests fell into that category. Use standardized category names from this list where applicable:
  - `documentation_creation`, `documentation_update`, `code_implementation`, `code_refactoring`, `code_migration`, `error_handling`, `git_operations`, `repo_setup`, `data_sanitization`, `project_configuration`, `configuration_change`, `advisory_question`, `factual_lookup`, `information_query`, `bug_fix`, `test_writing`, `debugging`
  If a task doesn't fit these categories, create an appropriate snake_case name.

- **outcome** (enum): The overall outcome of the session. One of:
  - `fully_achieved` — All user goals were accomplished
  - `partially_achieved` — Some goals were accomplished but others were not
  - `not_achieved` — The user's goals were not accomplished
  - `abandoned` — The user gave up or the session ended without resolution

- **user_satisfaction_counts** (object): For each user message, infer their satisfaction level from tone, corrections, and follow-up behavior. Keys are satisfaction levels, values are counts:
  - `happy` — User expressed explicit positive feedback ("perfect", "great", "exactly")
  - `likely_satisfied` — User continued without objection, accepted output, or gave neutral acknowledgment
  - `dissatisfied` — User corrected Claude, expressed frustration, or rejected output

- **claude_helpfulness** (enum): Overall assessment of how helpful Claude was. One of:
  - `essential` — Claude did work the user couldn't easily do themselves
  - `very_helpful` — Claude significantly accelerated the user's work
  - `somewhat_helpful` — Claude helped but required significant correction
  - `not_helpful` — Claude's contributions were mostly wrong or unhelpful

- **session_type** (enum): The pattern of interaction. One of:
  - `single_task` — One focused task from start to finish
  - `multi_task` — Multiple distinct tasks in sequence
  - `iterative_refinement` — One task refined through multiple rounds of feedback
  - `quick_question` — Brief Q&A, no significant code changes
  - `exploration` — User exploring/investigating without a fixed goal

- **friction_counts** (object): Count instances of friction by type. Keys are friction type names, values are counts. Use standardized types:
  - `wrong_approach` — Claude chose a fundamentally wrong technical approach
  - `buggy_code` — Claude produced code with bugs
  - `misunderstood_request` — Claude misinterpreted what the user asked for
  - `incomplete_sanitization` — Claude missed items in a cleanup/sanitization task
  - `missing_tool` — A required CLI tool or dependency was not available
  - `environment_mismatch` — Claude assumed wrong environment details (versions, OS, etc.)
  - `hallucination` — Claude stated something incorrect as fact
  - `slow_convergence` — Required many rounds to reach the right solution
  If no friction occurred, return an empty object `{}`.

- **friction_detail** (string): A 1-2 sentence narrative describing the most notable friction points in the session. Focus on what went wrong and what the user had to correct. If no friction, return an empty string.

- **primary_success** (string): The single most impactful capability Claude demonstrated. Use standardized values:
  - `multi_file_changes` — Successfully coordinated changes across multiple files
  - `correct_code_edits` — Produced correct code modifications
  - `fast_accurate_search` — Quickly found relevant code/information
  - `good_explanations` — Provided clear, helpful explanations
  - `good_debugging` — Successfully diagnosed and fixed bugs
  - `automation` — Automated a tedious manual process

- **brief_summary** (string): A 1-2 sentence summary of the session for use in aggregate reporting. Include what was requested and the outcome.

- **session_id** (string): Echo back the session ID provided.

### Output Format

Return ONLY valid JSON. No markdown, no explanation, no preamble.

### Example Output

{
  "underlying_goal": "Prepare a personal investment analysis codebase for public GitHub by creating documentation, migrating to uv package manager, and sanitizing all PII/sensitive data",
  "goal_categories": {
    "documentation_creation": 1,
    "code_migration": 1,
    "advisory_question": 1,
    "repo_setup": 1,
    "data_sanitization": 1
  },
  "outcome": "fully_achieved",
  "user_satisfaction_counts": {
    "likely_satisfied": 4
  },
  "claude_helpfulness": "essential",
  "session_type": "multi_task",
  "friction_counts": {
    "incomplete_sanitization": 1
  },
  "friction_detail": "Initial PII sanitization pass missed account numbers in filename patterns and dividend figures in README, requiring a second sweep.",
  "primary_success": "multi_file_changes",
  "brief_summary": "User wanted to prepare a personal investment analysis project for GitHub by creating CLAUDE.md, migrating from pip to uv, setting up .gitignore/README, and sanitizing all PII — all tasks were completed successfully.",
  "session_id": "063a1db9-4aee-4323-ace2-8d2e36ca4fe0"
}
```

---

## Phase 2: Cross-Session Aggregation & Report Synthesis Prompt

This prompt receives all facet JSONs and all session metadata JSONs as input, and produces the final structured report.

```
You are generating a comprehensive Claude Code usage insights report for a user. You have been provided with:

1. **Session facets**: One JSON per session containing qualitative analysis (goals, friction, satisfaction, outcomes).
2. **Session metadata**: One JSON per session containing quantitative data (tool counts, timestamps, languages, lines changed, response times, errors, git activity).

Analyze ALL sessions holistically and produce a JSON report with the following exact structure. Every field is required.

Your analysis should be:
- **Personalized**: Speak directly to this specific user's patterns, not generic advice
- **Evidence-based**: Every claim should trace back to specific sessions or aggregate data
- **Actionable**: Suggestions should be concrete and immediately usable
- **Honest**: Acknowledge where Claude fell short, not just where the user could improve
- **Engaging**: Write in a conversational, direct tone — not corporate or formulaic

---

### Output Schema

{
  "project_areas": {
    "areas": [
      {
        "name": "<descriptive area name>",
        "session_count": <number>,
        "description": "<2-3 sentence description of the work done in this area, with specific details from the sessions>"
      }
      // 3-6 areas, sorted by session_count descending
    ]
  },

  "interaction_style": {
    "narrative": "<3 paragraphs analyzing HOW the user works with Claude Code. Paragraph 1: What they primarily use it for and their overall approach. Paragraph 2: Their interaction pattern — do they specify upfront or iterate? How do they handle mistakes? Paragraph 3: Their tooling profile — which tools dominate, what languages, what this reveals about their workflow. Reference specific numbers (tool counts, session counts, achievement rates). Use **bold** for key phrases.>",
    "key_pattern": "<One-sentence summary of their defining usage pattern>"
  },

  "what_works": {
    "intro": "<One sentence summarizing their overall success rate and focus areas>",
    "impressive_workflows": [
      {
        "title": "<Short title>",
        "description": "<2-3 sentences describing what they did well, with specific evidence from sessions>"
      }
      // 2-4 impressive workflows
    ]
  },

  "friction_analysis": {
    "intro": "<One sentence identifying the primary source of friction>",
    "categories": [
      {
        "category": "<Category name>",
        "description": "<2-3 sentences describing the pattern AND a concrete suggestion to mitigate it>",
        "examples": [
          "<Specific example from a session>",
          "<Another specific example>"
        ]
      }
      // 2-4 friction categories, sorted by severity
    ]
  },

  "suggestions": {
    "claude_md_additions": [
      {
        "addition": "<The exact text to add to CLAUDE.md>",
        "why": "<Why this addition would help, referencing specific friction from sessions>",
        "prompt_scaffold": "<Where in CLAUDE.md to add it, e.g. 'Add under ## Architecture Decisions section'>"
      }
      // 3-6 additions, prioritized by impact
    ],
    "features_to_try": [
      {
        "feature": "<Claude Code feature name>",
        "one_liner": "<One-sentence description of the feature>",
        "why_for_you": "<Why this specific user would benefit, referencing their patterns>",
        "example_code": "<A ready-to-use code snippet or command the user can paste>"
      }
      // 2-4 features from: Custom Skills, Hooks, Headless Mode, MCP Servers, /commands, Sub-agents, Plan mode
    ],
    "usage_patterns": [
      {
        "title": "<Short title for the pattern>",
        "suggestion": "<One-sentence actionable suggestion>",
        "detail": "<2-3 sentences explaining why this matters for this user, with evidence>",
        "copyable_prompt": "<A ready-to-paste prompt the user can use in Claude Code>"
      }
      // 2-4 usage patterns
    ]
  },

  "on_the_horizon": {
    "intro": "<One sentence framing where the user is now and what's next>",
    "opportunities": [
      {
        "title": "<Opportunity name>",
        "whats_possible": "<2-3 sentences describing the autonomous/advanced workflow>",
        "how_to_try": "<One sentence on how to get started>",
        "copyable_prompt": "<A detailed, ready-to-paste prompt that demonstrates the workflow>"
      }
      // 2-3 forward-looking opportunities
    ]
  },

  "fun_ending": {
    "headline": "<A humorous one-liner about the most memorable thing that happened across all sessions — frame it like a news headline in quotes>",
    "detail": "<1-2 sentences providing the context behind the joke>"
  },

  "at_a_glance": {
    "whats_working": "<2-3 sentences on what the user does well with Claude Code. Reference a specific section for more detail.>",
    "whats_hindering": "<2-3 sentences on what's causing friction — split between Claude's faults and the user's workflow gaps. Reference a specific section.>",
    "quick_wins": "<2-3 sentences suggesting easy improvements. Reference a specific section.>",
    "ambitious_workflows": "<2-3 sentences on advanced workflows they could try. Reference a specific section.>"
  }
}

### Aggregation Guidelines

When computing aggregate statistics for the report:

- **Top-level stats**: Sum across all session metadata: total user messages, total lines added/removed, total unique files modified, count of active days, messages per active day, total git commits.
- **Tool usage chart ("Top Tools Used")**: Sum `tool_counts` across all sessions, show top 6.
- **Languages chart**: Sum `languages` across all sessions.
- **Goal categories chart ("What You Wanted")**: Sum `goal_categories` across all facets, show top 6.
- **Session types chart**: Count sessions by `session_type` from facets.
- **Friction types chart**: Sum `friction_counts` across all facets.
- **Success types chart ("What Helped Most")**: Count sessions by `primary_success` from facets.
- **Outcomes chart**: Count sessions by `outcome` from facets.
- **Satisfaction chart**: Sum `user_satisfaction_counts` across all facets.
- **Response time distribution**: Bucket all `user_response_times` from metadata into: 2-10s, 10-30s, 30s-1m, 1-2m, 2-5m, 5-15m, >15m. Compute median and average.
- **Time of day**: Use `message_hours` from metadata to build hourly histogram.
- **Tool errors**: Sum `tool_error_categories` across all metadata.
- **Multi-clauding**: Detect overlapping sessions by comparing `user_message_timestamps` across sessions.
- **Project areas**: Cluster sessions by `underlying_goal` and `project_path` from facets/metadata. Group related sessions into 3-6 thematic areas.

### Analysis Guidelines

- **Friction categories**: Don't just list friction types — identify PATTERNS across sessions. Group related friction events into 2-4 higher-level categories with actionable mitigation advice.
- **CLAUDE.md suggestions**: Each suggestion should directly address a documented friction pattern. Include the exact text to add, not a vague recommendation.
- **Features to try**: Only suggest features that directly address observed patterns. Include working code snippets.
- **Usage patterns**: Focus on workflow changes that would have prevented specific friction events.
- **On the horizon**: Suggest workflows that build on what the user already does well, extended to more autonomous or parallel execution.
- **Fun ending**: Pick the single most amusing or ironic event across all sessions. Frame it as a humorous headline.

### Output Format

Return ONLY valid JSON matching the schema above. No markdown wrapping, no explanation.
```

---

## Phase 3: HTML Report Rendering (Deterministic Template)

The HTML report is **not generated by the LLM** — it is a static HTML template that the CLI populates with:

1. The JSON from Phase 2 (narrative sections, suggestions, etc.)
2. The aggregate statistics computed from session metadata (charts, bar graphs, stats row)

The template uses:
- **Inter font** via Google Fonts
- **Color-coded sections**: green for wins, red for friction, blue for CLAUDE.md suggestions, purple for horizon, yellow/amber for at-a-glance and fun ending
- **Horizontal bar charts** rendered as CSS `div` elements with percentage-width fills
- **Copy buttons** with clipboard API integration for all code snippets and CLAUDE.md suggestions
- **Timezone selector** for the time-of-day histogram with client-side JavaScript re-rendering
- **Collapsible sections** for optional detail areas
- **Checkbox + "Copy All Checked"** UI for CLAUDE.md addition suggestions

The stats row shows: Messages, Lines (+added/-removed), Files, Days, Msgs/Day.

The full section order in the rendered HTML:
1. Title + subtitle (date range, session count, message count)
2. At a Glance (amber highlight box with cross-references)
3. Navigation TOC (pill links)
4. Stats row
5. What You Work On (project areas cards + charts: What You Wanted, Top Tools Used, Languages, Session Types)
6. How You Use Claude Code (narrative paragraphs + key insight box + Response Time Distribution + Multi-Clauding + Time of Day + Tool Errors)
7. Impressive Things You Did (green cards + charts: What Helped Most, Outcomes)
8. Where Things Go Wrong (red cards + charts: Primary Friction Types, Inferred Satisfaction)
9. Existing CC Features to Try (CLAUDE.md suggestions with checkboxes + feature cards with code snippets)
10. New Ways to Use Claude Code (pattern cards with copyable prompts)
11. On the Horizon (purple gradient cards with copyable prompts)
12. Fun ending (amber box with headline + detail)
