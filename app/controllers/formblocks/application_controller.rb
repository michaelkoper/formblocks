# frozen_string_literal: true

module Formblocks
  # Root of the engine's PUBLIC surface: the assets and the form pages. These
  # stay on a plain ActionController::Base deliberately — a visitor filling
  # in a form must not be routed through a host's admin controller.
  #
  # The admin's root is DashboardController, where
  # `config.base_controller_class` applies.
  class ApplicationController < ActionController::Base
    include RequestContext

    helper Formblocks::ApplicationHelper
    protect_from_forgery with: :exception
  end
end
