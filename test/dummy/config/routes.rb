# frozen_string_literal: true

Rails.application.routes.draw do
  mount AgenticHarness::Engine => "/_agent"
  root to: proc { [200, {"Content-Type" => "text/plain"}, ["dummy host root"]] }
end
