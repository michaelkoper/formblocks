# frozen_string_literal: true

require 'uri'

module Formblocks
  # Which tenant is asking and whether they may administer forms. A concern
  # rather than inherited behaviour because the engine has two controller
  # roots: the public pages hang off ActionController::Base, and the admin
  # hangs off whatever the host set as `base_controller_class`.
  module RequestContext
    extend ActiveSupport::Concern

    private

    def formblocks_admin_layout
      Formblocks.config.admin_layout
    end

    # The tenant for this request (nil = the single global collection). Every
    # admin read and write scopes to it.
    def current_tenant
      return @current_tenant if defined?(@current_tenant)

      @current_tenant = Formblocks.tenant(request)
    end

    def tenant_forms
      Form.for_tenant(current_tenant)
    end

    # Server-side gate for the admin. Default: development only.
    def require_admin
      return if Formblocks.admin?(request)

      render plain: I18n.t('formblocks.forbidden'), status: :forbidden
    end

    # Browser referrers can carry password-reset tokens, signed ids and
    # campaign details in their query or fragment. Keep only a plain HTTP(S)
    # origin and path; anything else becomes nil before it is stored.
    def clean_page_url(value)
      uri = URI.parse(value.to_s)
      return unless uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil?

      uri.query = nil
      uri.fragment = nil
      uri.to_s.first(500)
    rescue URI::InvalidURIError
      nil
    end

    # Turbo submits forms with a turbo-stream Accept header; a plain browser
    # submit (no JavaScript) does not. Autosave answers the former with 204.
    def turbo_request?
      request.format.turbo_stream?
    end
  end
end
