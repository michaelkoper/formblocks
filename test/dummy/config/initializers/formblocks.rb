# frozen_string_literal: true

Formblocks.configure do |config|
  # Who can build forms, read responses and change settings at the mount
  # path. Defaults to development only — override before deploying.
  # config.authorize_admin = ->(request) { request.env["warden"]&.user&.admin? }
  #
  # Two ways to put the builder inside an admin you already have.
  #
  # The layout only — the gem's controllers, your shell:
  # config.admin_layout = "admin/application"
  #
  # Or the whole stack. Name the controller your own admin inherits from and
  # the builder picks up its layout, helpers, authentication and any request
  # context its before_actions set up. Only the admin inherits it; the public
  # form pages stay on the engine's own controller.
  # config.base_controller_class = "Admin::BaseController"

  # Multi-tenancy (optional). Scope forms, responses and settings to a
  # tenant — each Account/Organization its own set of forms. Return an
  # opaque key (nil = one global collection, the default). A GlobalID is the
  # recommended key; an id, subdomain or slug work too.
  # config.tenant = ->(request) { Current.account&.to_gid&.to_s }

  # Called with each saved Formblocks::Response — notify Slack, send an
  # email, create a lead. `response.answers` is a hash keyed by block key
  # ("email", "name", ...); `response.form` is the form it came from.
  # config.on_submit = ->(response) {}

  # Logo and image uploads (requires Active Storage).
  # config.attachments = true
  # config.max_upload_size = 5.megabytes
  # config.storage_service = :formblocks

  # Brand defaults, used when neither the form nor the settings page set one.
  # config.default_primary_color = "#111827"
  # config.default_button_text_color = "#ffffff"

  # Form templates on the "New form" page. Add your own or drop a built-in.
  # config.templates["webinar"] = { title: "Webinar signup", pages: [...] }
  # config.templates.delete("feedback")

  # Per-IP throttle for the public submit endpoint (Rails 7.2+; ignored on 7.1).
  # config.rate_limit = { to: 10, within: 1.minute }

  # Paths, written by `mount_formblocks` in routes.rb. Set these only if you
  # mount the engine manually.
  # config.mount_path = "/forms"
  # config.public_path = "/f"
end
