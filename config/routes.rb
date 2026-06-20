# frozen_string_literal: true

AgenticHarness::Engine.routes.draw do
  # ── Admin night-shifts (cross-worktree dashboard) ─────────────────
  namespace :admin do
    resources :night_shifts, only: [:index, :show], param: :id,
              constraints: {id: /[A-Za-z0-9][A-Za-z0-9_-]*/} do
      member do
        get "doc/:doc",
            to: "night_shifts#document",
            as: :document,
            format: false,
            constraints: {doc: /[A-Za-z0-9.\-_]+/}
      end
    end
  end

  # ── Per-worktree anonymous night-shift artifact viewer ─────────────
  get "/night-shift",      to: "night_shift#index",    as: :night_shift
  get "/night-shift/:doc", to: "night_shift#document", as: :night_shift_doc,
      format: false,
      constraints: {doc: /[A-Za-z0-9.\-_]+/}

  # ── Docs system ─────────────────────────────────────────────────────
  get "/docs",      to: "docs#index", as: :docs
  get "/docs/*key", to: "docs#show",  as: :doc, defaults: {format: :html}

  # ── Kanban board ───────────────────────────────────────────────────
  get   "/kanban",                       to: "kanban#index",          as: :kanban
  get   "/kanban/backlog",               to: "kanban#backlog",        as: :kanban_backlog
  patch "/kanban/:column/reorder",       to: "kanban#reorder_column", as: :kanban_column_reorder,
        constraints: {column: /\d{2}_\w+/}
  get   "/kanban/:column/:slug",         to: "kanban#show",           as: :kanban_task,
        constraints: {column: /\d{2}_\w+/, slug: /[\w-]+/}
  get   "/kanban/:column/:slug/edit",    to: "kanban#edit",           as: :edit_kanban_task,
        constraints: {column: /\d{2}_\w+/, slug: /[\w-]+/}
  patch "/kanban/:column/:slug/move",    to: "kanban#move",           as: :kanban_task_move,
        constraints: {column: /\d{2}_\w+/, slug: /[\w-]+/}
  post  "/kanban/:column/:slug/archive", to: "kanban#archive",        as: :kanban_task_archive,
        constraints: {column: /\d{2}_\w+/, slug: /[\w-]+/}
  patch "/kanban/:column/:slug",         to: "kanban#update",
        constraints: {column: /\d{2}_\w+/, slug: /[\w-]+/}
  delete "/kanban/:column/:slug",        to: "kanban#destroy",
        constraints: {column: /\d{2}_\w+/, slug: /[\w-]+/}
end
