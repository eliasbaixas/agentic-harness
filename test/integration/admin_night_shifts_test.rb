# frozen_string_literal: true

require "test_helper"

class AdminNightShiftsTest < ActionDispatch::IntegrationTest
  def make_shift(parent, slug, files)
    shift = parent / slug
    shift.mkpath
    files.each { |name, content| (shift / name).write(content) }
    raise "git init failed for #{shift}" unless system("git", "init", "-b", "main", "-q", shift.to_s)
    shift
  end

  def test_index_lists_directories_under_the_configured_shifts_root
    with_fixture_layout do |tmp|
      make_shift(tmp / "shifts", "T-0010-some-shift", "TASK.md" => "# T-0010 spec")
      make_shift(tmp / "shifts", "T-0011-another", "PROGRESS.md" => "# in progress")

      sign_in_admin
      get "/_agent/admin/night_shifts"
      assert_response :success
      assert_match "T-0010-some-shift", body
      assert_match "T-0011-another", body
    end
  end

  def test_document_renders_a_specific_artifact
    with_fixture_layout do |tmp|
      make_shift(tmp / "shifts", "T-0050-fixture",
                 "TASK.md" => "# Goal\n\nMake everything work.\n")

      sign_in_admin
      get "/_agent/admin/night_shifts/T-0050-fixture/doc/TASK.md"
      assert_response :success
      assert_match "Goal", body
      assert_match "Make everything work", body
    end
  end

  def test_unknown_slug_is_404
    with_fixture_layout do |_tmp|
      sign_in_admin
      get "/_agent/admin/night_shifts/nonexistent-slug"
      assert_response :not_found
    end
  end

  def test_non_admin_redirected
    with_fixture_layout do |_tmp|
      sign_in_non_admin
      get "/_agent/admin/night_shifts"
      assert_response :redirect
    end
  end
end
