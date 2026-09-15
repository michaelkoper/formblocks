# frozen_string_literal: true

module Formblocks
  # Host-tunable settings. Everything has a safe default, so a fresh install
  # works with zero configuration; the hooks below let an app decide who may
  # build forms, which tenant they belong to, and what happens on submit.
  class Configuration
    # The gem's own admin layout. Compared against, so DashboardController can
    # tell "the host left this alone" from "the host chose this".
    DEFAULT_ADMIN_LAYOUT = 'formblocks/application'

    # Your product's name, shown in page titles ("Contact form · Nusii") and
    # as the alt text of a logo. nil resolves to the Rails application name.
    attr_accessor :app_name

    # Per-request gate for the builder, responses and settings. Defaults to
    # development only — override it before deploying, e.g. with an admin check.
    attr_accessor :authorize_admin

    # Layout used by the admin pages. Override this to render the builder
    # inside your app's admin shell, e.g. "admin/application".
    attr_accessor :admin_layout

    # The controller the ADMIN inherits from, as a String so it resolves
    # lazily. Default: a plain 'ActionController::Base', where
    # `authorize_admin` is the only gate. Name the controller your own admin
    # already inherits from and the builder adopts that whole stack — layout,
    # helpers, authentication, request context.
    #
    # Only the admin uses it. The public form pages stay on the engine's own
    # controller, so an admin base controller here can never demand a staff
    # session from a visitor filling in a form.
    attr_accessor :base_controller_class

    # Resolve the current tenant (optional, for multi-tenant apps). Return an
    # opaque key — a GlobalID, an id, a subdomain, a slug — or nil. Receives
    # the request. nil (the default) is a single, global collection. Forms,
    # responses and the settings all scope to whatever this returns.
    attr_accessor :tenant

    # Called with each saved Formblocks::Response — notify Slack, send an
    # email, create a lead. Runs inline after save; keep it fast or hand off
    # to a job.
    attr_accessor :on_submit

    # Logo and image-block uploads. Requires Active Storage in the host; set
    # false to hide every upload even when Active Storage is loaded.
    attr_accessor :attachments
    attr_accessor :max_upload_size

    # The Active Storage service that stores uploads — form logos, the global
    # logo, image blocks — as a service name from the host's
    # config/storage.yml (e.g. a dedicated bucket or folder, or an entry with
    # provider options like Cloudinary's folder/tags). nil, the default, uses
    # the environment's default service. Read when the models load, so set it
    # in an initializer.
    attr_accessor :storage_service

    # Per-IP throttle for the public submit endpoint, as keyword arguments for
    # Rails' rate limiter (Rails 7.2+; ignored on 7.1). Read once when the
    # controller loads — set it in an initializer. nil disables throttling.
    attr_accessor :rate_limit

    # Brand defaults when neither the form nor the settings page set a color.
    attr_accessor :default_primary_color, :default_button_text_color

    # Where the admin engine is mounted, and where public forms live. Both are
    # written by `mount_formblocks`; set them here only if you mount manually.
    attr_accessor :mount_path, :public_path

    # Form templates offered on the "New form" page, keyed by an identifier.
    # See Formblocks::Templates for the built-in ones and the definition shape.
    attr_reader :templates

    def initialize
      @app_name = nil
      @authorize_admin = ->(_request) { Rails.env.development? }
      @admin_layout = DEFAULT_ADMIN_LAYOUT
      @base_controller_class = 'ActionController::Base'
      @tenant = ->(_request) {}
      @on_submit = ->(_response) {}
      @attachments = true
      @max_upload_size = 5 * 1024 * 1024
      @storage_service = nil
      @rate_limit = { to: 10, within: 60 }
      @default_primary_color = '#111827'
      @default_button_text_color = '#ffffff'
      @mount_path = '/forms'
      @public_path = '/f'
      @templates = Templates.builtin
    end
  end
end
