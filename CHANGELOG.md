# Changelog

All notable changes to this gem are documented here.

## [Unreleased]

### Added
- Initial release.
- `AgenticHarness::Engine` mountable Rails engine.
- `AgenticHarness::Configuration` DSL with `tasks_root`, `docs_root`,
  `night_shifts_dir`, `authenticate_with`, `authorize_with`.
- Controllers: `KanbanController`, `DocsController`, `NightShiftController`,
  `Admin::NightShiftsController`.
- Models: `TaskPage`, `DocsPage`.
- Services: `NightShifts::{Scanner, FileLoader, MarkdownRenderer}`.
- Helper: `NightShiftHelper`.

### Known limitations
- No dummy app for engine-level integration tests yet.
- No GitHub Actions CI yet.
- Stimulus controller for the kanban drag-and-drop ships as a JS file under
  `app/javascript/agentic_harness/controllers/` but is not auto-registered;
  host app needs to wire it in for now.
