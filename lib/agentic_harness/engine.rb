# frozen_string_literal: true

require "rails/engine"

module AgenticHarness
  # Mountable Rails engine that adds a lightweight agentic-development
  # harness (kanban over markdown files, docs viewer, night-shift artifact
  # surfaces) to any Rails host app.
  #
  # Mount at any prefix in the host app's routes:
  #
  #   mount AgenticHarness::Engine => "/_agent"
  #
  # All engine routes are isolated under the `AgenticHarness` namespace, so
  # they won't collide with host routes regardless of where you mount them.
  class Engine < ::Rails::Engine
    isolate_namespace AgenticHarness

    # Append the engine's `app/javascript/agentic_harness/` directory to the
    # host's asset paths so the Stimulus controllers (e.g. kanban drag-drop)
    # ship without manual copying.
    config.autoload_paths << root.join("app/services")
  end
end
