# frozen_string_literal: true

require "test_helper"

# The dummy host mounts the engine at "/_agent". These tests verify that
# routes resolve at the engine prefix and that the host root still works.
class EngineMountTest < ActionDispatch::IntegrationTest
  def test_host_root_responds_independently_of_engine
    get "/"
    assert_equal 200, status
    assert_match "dummy host root", body
  end

  def test_engine_routes_resolve_under_the_mount_point
    # Reach each of the four surfaces through the mount prefix and assert we
    # don't 404. Auth gates may return 401/302; we just need the routes to
    # resolve to engine controllers (not to nowhere).
    # /_agent/night-shift is intentionally omitted — that controller returns
    # 404 unless the running process is inside a night-shift worktree, which
    # is the correct production behaviour.
    [
      "/_agent/kanban",
      "/_agent/docs",
      "/_agent/admin/night_shifts",
    ].each do |path|
      get path
      refute_equal 404, status, "expected #{path} to resolve, got 404"
    end
  end
end
