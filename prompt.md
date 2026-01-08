# Ralph Agent Instructions

## Your Task

1. Read `tasks.json`
2. Read `progress.txt`
   (check Codebase Patterns first)
3. Check you're on the correct branch
4. Pick highest priority story
   where `passes: false`
5. Implement that ONE story
6. Run typecheck and tests
7. **For UI/visual stories (VIS-*):**
   Use Playwright MCP to verify changes:
   - Navigate to the relevant page
   - Take a screenshot
   - Verify the visual result matches criteria
   Not complete until verified with screenshot.
8. If you discovered a reusable pattern,
   update/create AGENTS.md in the relevant
   directory (permanent docs for future agents)
9. Commit: `feat: [ID] - [Title]`
10. Update tasks.json: `passes: true`
    Update story `notes` field with implementation details
11. Append learnings to progress.txt

## Progress Format

APPEND to progress.txt:

## [Date] - [Story ID]
- What was implemented
- Files changed
- **Learnings:**
  - Patterns discovered
  - Gotchas encountered
---

## Codebase Patterns

Add reusable patterns to the TOP 
of progress.txt:

## Codebase Patterns
- Migrations: Use IF NOT EXISTS
- React: useRef<Timeout | null>(null)

## Stop Condition

If ALL stories pass, reply:
<promise>COMPLETE</promise>

Otherwise end normally.