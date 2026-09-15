# frozen_string_literal: true

require 'turbo-rails'
require 'stimulus-rails'

require 'formblocks/version'
require 'formblocks/configuration'
require 'formblocks/assets'
require 'formblocks/templates'
require 'formblocks/seeds'
require 'formblocks/engine'

# Formblocks: a block-based form builder for Rails. Forms are built from
# blocks (content and inputs) spread over pages, published at a public URL,
# and their responses land in your own database with a dashboard and CSV export.
module Formblocks
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    # The class the admin controllers inherit from. Resolved on every call
    # rather than memoized, so a host that reassigns base_controller_class in
    # a reloadable initializer is not pinned to a stale, unloaded constant.
    def base_controller
      config.base_controller_class.to_s.constantize
    end

    # Can this request use the builder and read responses? Checked by every
    # admin action, and by the public page to allow previews of drafts.
    def admin?(request)
      !!config.authorize_admin.call(request)
    end

    # The tenant key for this request, or nil for the single global collection.
    # Normalized to a string so `where(tenant:)` is consistent whether the
    # resolver returns a GlobalID, an integer id, or a slug.
    def tenant(request)
      config.tenant.call(request).presence&.to_s
    end

    # Forms belonging to a host record, keyed by its GlobalID.
    def for(record)
      Form.for_tenant(tenant_key_for(record))
    end

    # The product name for titles and alt text: config.app_name, else the
    # Rails application's module name, verbatim ("Nusii", "SupeRails").
    def app_name
      config.app_name.presence || rails_app_name
    end

    # Logo and image uploads need Active Storage loaded in the host.
    def attachments?
      config.attachments && defined?(::ActiveStorage) ? true : false
    end

    private

    def rails_app_name
      Rails.application.class.module_parent_name
    rescue StandardError
      'this app'
    end

    def tenant_key_for(record)
      record.respond_to?(:to_gid) ? record.to_gid.to_s : record.to_s
    end
  end
end
