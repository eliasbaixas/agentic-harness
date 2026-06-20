# frozen_string_literal: true

require "test_helper"

class DocsControllerTest < ActionDispatch::IntegrationTest
  def test_index_lists_documented_sections_for_admins
    with_fixture_layout do |tmp|
      (tmp / "docs/adr/0001-use-pgvector-for-embeddings.md").write(
        "# Use pgvector\n\nThe canonical embedding store decision.\n"
      )
      (tmp / "docs/features").mkpath
      (tmp / "docs/features/rag.md").write("# RAG\n")
      sign_in_admin
      get "/_agent/docs"
      assert_response :success
      # Index shows section headers + per-doc cards keyed by filename.
      assert_match "0001 use pgvector for embeddings", body
      assert_match "Rag", body
    end
  end

  def test_show_renders_the_markdown_body
    with_fixture_layout do |tmp|
      (tmp / "docs/adr/0001-use-pgvector-for-embeddings.md").write(
        "# Decision\n\npgvector is the chosen vector store.\n"
      )
      sign_in_admin
      get "/_agent/docs/adr/0001-use-pgvector-for-embeddings"
      assert_response :success
      assert_match "Decision", body
      assert_match "pgvector is the chosen vector store", body
    end
  end

  def test_show_returns_404_for_missing_key
    with_fixture_layout do |_tmp|
      sign_in_admin
      get "/_agent/docs/no/such/key"
      assert_response :not_found
    end
  end

  def test_authentication_required
    with_fixture_layout do |_tmp|
      sign_out_for_test
      get "/_agent/docs"
      assert_response :unauthorized
    end
  end

  def test_authorization_blocks_non_admins
    with_fixture_layout do |_tmp|
      sign_in_non_admin
      get "/_agent/docs"
      assert_response :redirect
    end
  end
end
