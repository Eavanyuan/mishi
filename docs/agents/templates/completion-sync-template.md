# Completion Sync Template

```md
## Completion Sync
- sync_id: SYNC-YYYYMMDD-<role>-001
- task_id: MISHI-XXX
- owner: <role>
- proposed_state: review
- updated_at: YYYY-MM-DD HH:mm
- evidence_link: collab/<domain>/YYYY-MM-DD-<topic>-<role>.md
- summary: <what is completed / changed>
- next_action: <owner + due>
```

If blocked:

```md
## Completion Sync
- sync_id: SYNC-YYYYMMDD-<role>-002
- task_id: MISHI-XXX
- owner: <role>
- proposed_state: blocked
- updated_at: YYYY-MM-DD HH:mm
- evidence_link: collab/<domain>/YYYY-MM-DD-<topic>-<role>.md
- summary: <blocked context>
- block_reason: <reason>
- next_check_at: YYYY-MM-DD HH:mm
- next_action: <owner + due>
```
