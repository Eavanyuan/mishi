# Shared Workspace Settings (v2)

## 1) Directory Map
- `collab/00_context`: fixed context and baseline links
- `collab/10_requirements`: PRD updates, user stories, acceptance criteria
- `collab/20_architecture`: architecture decisions, sequence diagrams, risk docs
- `collab/30_design`: interaction notes, design tokens, UI redlines
- `collab/40_backend`: service design, DB migration notes, task split
- `collab/50_frontend`: web/H5 implementation notes and component mapping
- `collab/60_app`: iOS/Android/Flutter implementation notes
- `collab/70_api_contracts`: OpenAPI/Proto changes and compatibility notes
- `collab/80_test`: test plan, test reports, bug list
- `collab/90_release`: release checklist, rollback plan, deployment notes
- `collab/99_decisions`: ADRs and key trade-off records
- `collab/handoff`: scheduling and cross-role handoff artifacts (Coordinator-owned)

## 2) Ownership and Write Authority
- PM owns `10_requirements`
- Architect owns `20_architecture` and `99_decisions`
- Frontend owns `50_frontend`
- Backend owns `40_backend`
- App owns `60_app`
- Coordinator owns `handoff` and `90_release`

Strict rule:
- `collab/handoff/daily-sync.md` and `collab/handoff/dependency-queue.md` are write-only by Coordinator.
- Other roles must not directly edit these two files.
- Other roles submit updates through role docs using a `Scheduling Request` section.

## 3) Collaboration Protocol
- File naming: `YYYY-MM-DD-topic-owner.md`
- Daily sync source of truth: `collab/handoff/daily-sync.md`
- Dependency source of truth: `collab/handoff/dependency-queue.md`
- New decision must be recorded in `collab/99_decisions`
- API breaking/non-breaking changes must update `collab/70_api_contracts` before implementation merge

### Completion Sync Protocol (mandatory)
Goal: allow non-Coordinator roles to report completion without writing `collab/handoff/*`.

Rules:
- Any role except Coordinator must sync task progress in its own domain document.
- For each completed or blocked task, append a `Completion Sync` block at document end.
- Coordinator scans latest role docs and converts valid sync blocks into queue state transitions.
- Non-Coordinator roles can only "propose state"; only Coordinator can "apply state" in dependency queue.

`Completion Sync` required fields:
- `sync_id`: unique id, e.g. `SYNC-20260317-arch-001`
- `task_id`: queue task id, e.g. `MISHI-018`
- `owner`: role id
- `proposed_state`: `review | blocked | cancelled` (non-Coordinator must not write `done`)
- `updated_at`: `YYYY-MM-DD HH:mm`
- `evidence_link`: domain file path or artifact link
- `summary`: what changed
- `next_action`: who does what next, with due time

State proposal policy:
- Work finished by owner: propose `review` + attach `evidence_link`
- Dependency blocked: propose `blocked` + include blocker and `next_check_at`
- Scope dropped: propose `cancelled` + include reason and approver candidate

## 4) Unified Task State Machine
Allowed states:
- `todo`
- `in_progress`
- `blocked`
- `review`
- `done`
- `cancelled`

Rules:
- Only Coordinator can change task state in dependency queue.
- `done` requires explicit `approver` and `evidence`.
- Any `blocked` task must include `block_reason`, `owner`, `next_check_at`.

## 5) Approval Chain
- Requirement/scope approval: PM
- Architecture/API contract approval: Architect
- Backend implementation acceptance: Backend + Coordinator
- Frontend implementation acceptance: Frontend + Coordinator
- App implementation acceptance: App + Coordinator
- Release gate approval: Coordinator (after PM + Architect sign-off)

## 6) Conflict Policy
If docs conflict with code:
1. Role owner records issue in role domain doc
2. Add `Scheduling Request` with urgency and impact
3. Architect proposes technical resolution
4. PM confirms scope/time impact
5. Coordinator updates queue and execution order

## 7) Audit and Traceability
Each queue item must contain:
- `task_id`, `title`, `owner`, `approver`, `state`, `priority`
- `depends_on`, `updated_at`, `evidence_link`

Every daily sync entry must be append-only with:
- `timestamp`, `event_id`, `actor`, `change_summary`, `affected_tasks`
