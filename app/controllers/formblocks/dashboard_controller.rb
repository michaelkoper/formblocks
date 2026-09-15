# frozen_string_literal: true

module Formblocks
  # Root of the ADMIN surface: the forms list, the builder, responses and
  # settings.
  #
  # Inherits from `config.base_controller_class` — by default a plain
  # ActionController::Base, which is why `authorize_admin` exists. Point it at
  # the controller your own admin already inherits from and the builder picks
  # up that stack wholesale: your layout, helpers, authentication, and
  # whatever request context your before_actions establish.
  class DashboardController < Formblocks.base_controller
    include RequestContext
    include ActionView::RecordIdentifier

    helper Formblocks::ApplicationHelper

    # A host base controller brings its own layout, and declaring one here
    # would override it. So the gem only claims the layout when it owns the
    # decision: no host base controller, or a host that named an
    # `admin_layout` explicitly.
    layout :formblocks_admin_layout unless superclass != ActionController::Base &&
                                           Formblocks.config.admin_layout == Configuration::DEFAULT_ADMIN_LAYOUT

    before_action :require_admin

    # A host base controller has configured CSRF already; declaring it twice
    # would run the check twice.
    protect_from_forgery with: :exception if superclass == ActionController::Base

    private

    def set_form
      @form = tenant_forms.find(params[:form_id] || params[:id])
    end

    def builder_path(anchor = nil)
      edit_form_path(@form, anchor:)
    end
  end
end
