# frozen_string_literal: true

require "test_helper"

class KanbanControllerTest < ActionDispatch::IntegrationTest
  def test_index_renders_columns_and_lists_task_cards
    with_fixture_layout do |tmp|
      card = tmp / "tasks/cards/2026/06/T-0001-add-something-cool.md"
      card.write(<<~MD)
        ---
        title: Add something cool
        category: product
        ---

        # Add something cool

        Body of the card.
      MD
      todo_link = tmp / "tasks/10_todo/T-0001-add-something-cool.md"
      FileUtils.ln_s(card, todo_link)

      sign_in_admin
      get "/_agent/kanban"
      assert_response :success
      assert_match "T-0001", body
    end
  end

  def test_show_renders_a_single_card
    with_fixture_layout do |tmp|
      card = tmp / "tasks/cards/2026/06/T-0042-explore.md"
      card.write("---\ntitle: Explore\n---\n\nbody")
      FileUtils.ln_s(card, tmp / "tasks/10_todo/T-0042-explore.md")

      sign_in_admin
      get "/_agent/kanban/10_todo/T-0042-explore"
      assert_response :success
      assert_match "Explore", body
    end
  end

  def test_authentication_required
    with_fixture_layout do |_tmp|
      sign_out_for_test
      get "/_agent/kanban"
      assert_response :unauthorized
    end
  end
end
