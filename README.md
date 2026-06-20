# Agentic Harness

[![Ruby](https://img.shields.io/badge/ruby-3.2+-CC342D.svg?style=flat-square)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-7.1+-CC0000.svg?style=flat-square)](https://rubyonrails.org)

A lightweight Rails engine that adds surfaces for **agentic / unattended
development work** alongside your normal app:

- **Kanban board** over markdown task files (`tasks/cards/<YYYY>/<MM>/T-NNNN-*.md`)
  with status columns, drag-and-drop, and in-browser edit.
- **Docs viewer** for in-repo markdown (`docs/**/*.md`) — including ADRs,
  feature docs, runbooks. URL-readable (`/docs/adr/0001-use-pgvector-for-embeddings`).
- **Night-shift artifact surfaces** for autonomous agents working in
  parallel git worktrees:
  - `/night-shift` — anonymous, per-worktree viewer of `TASK.md`,
    `DECISIONS.md`, `PROGRESS.md`, `RESULTS.md` (only resolves when the
    Rails process is running inside a `night-shift/<slug>` worktree).
  - `/admin/night_shifts` — cross-worktree dashboard scanning
    `~/night-shifts/*`, with per-shift git status and artifacts.

Has been used in anger for ~6 months on a production Rails project
running multi-worktree agentic development.

## Installation

```ruby
# Gemfile
gem "agentic_harness", git: "https://github.com/eliasbaixas/agentic-harness"
```

Mount the engine at any prefix:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount AgenticHarness::Engine => "/_agent"
end
```

## Configuration

```ruby
# config/initializers/agentic_harness.rb
AgenticHarness.configure do |c|
  c.tasks_root        = Rails.root.join("backlog")    # default: Rails.root/tasks
  c.docs_root         = Rails.root.join("docs")       # default: Rails.root/docs
  c.night_shifts_dir  = "~/work/shifts"               # default: ~/night-shifts
  c.authenticate_with = :authenticate_user!           # default: same
  c.authorize_with    = ->(controller) {              # default: current_user&.admin?
    controller.current_user&.admin?
  }
end
```

`authenticate_with` accepts a symbol (host before_action name) or a Proc.
`authorize_with` accepts a Proc receiving the controller; return truthy to
allow, falsy to redirect to `main_app.root_path`. Set either to `nil` to
disable.

The per-worktree night-shift viewer (`/night-shift`) bypasses both,
because the access-control is the worktree itself — if you can reach the
preview server, you already have the files on disk.

## Filesystem conventions

```
tasks/
  cards/2026/04/T-0041-add-some-cool-feature.md
  00_inbox/T-0041-...md          → symlink to ../cards/2026/04/T-0041-...md
  10_todo/T-0030-...md           → symlink
  20_in_progress/
  30_review/
  40_done/
  90_archive/
  BACKLOG.md
  PRIORITIES.md

docs/
  README.md
  features/rag.md
  adr/0001-use-pgvector-for-embeddings.md
  controllers/rag.md
```

Card filename format: `T-NNNN-<short-slug>.md`. The per-shift slug is the
filename minus `.md`. Night-shift worktrees live at `~/night-shifts/<slug>/`
with `TASK.md` at the root.

## Status

**v0.1 — extracted, not yet engine-tested.** The code is namespaced into
`AgenticHarness::*` and the engine boots, but the engine's own test suite
(with a dummy Rails app) is the next iteration. The extracted code is
covered by the host project's tests; the engine packaging itself needs
integration coverage before tagging a stable release.

Outstanding:
- [ ] Dummy app for engine tests
- [ ] CI (GitHub Actions)
- [ ] Asset pipeline integration docs (Stimulus controller for kanban)
- [ ] First gem release

## License

MIT — see `MIT-LICENSE`.
