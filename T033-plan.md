# T033 Plan: Update Binding Index

## Task Analysis
- Run the `tools/reindex.rb` script to update the binding index file
- Verify that the index correctly reflects all rewritten bindings (T021-T030)
- Commit the updated index file

## Current State Assessment
- All bindings (T021-T030) have been rewritten in the natural language format
- The `tools/reindex.rb` script was updated in T005 to handle the new format
- The script was successfully tested in T009 and has already been used to update the tenet index in T020

## Implementation Steps
1. Check the current state of the binding index
2. Run the `tools/reindex.rb` script to update the index
3. Verify that the updated index accurately reflects all rewritten bindings:
   - Check that all bindings are included
   - Verify that summaries are accurate
   - Ensure proper linking
4. Commit the changes to the index file
5. Update TODO.md to mark the task as complete

## Success Criteria
- The binding index is successfully regenerated
- The index accurately reflects all rewritten bindings (T021-T030)
- Changes are properly committed
- Task is marked as complete in TODO.md