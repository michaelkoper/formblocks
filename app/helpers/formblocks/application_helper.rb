# frozen_string_literal: true

module Formblocks
  module ApplicationHelper
    ICONS = {
      plus: '<path d="M12 5v14M5 12h14"/>',
      trash: '<path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6M10 11v6M14 11v6"/>',
      up: '<path d="M12 19V5M5 12l7-7 7 7"/>',
      down: '<path d="M12 5v14M19 12l-7 7-7-7"/>',
      grip: '<circle cx="9" cy="6" r="1.5"/><circle cx="15" cy="6" r="1.5"/><circle cx="9" cy="12" r="1.5"/>' \
            '<circle cx="15" cy="12" r="1.5"/><circle cx="9" cy="18" r="1.5"/><circle cx="15" cy="18" r="1.5"/>',
      check: '<circle cx="12" cy="12" r="10"/><path d="M8 12l3 3 5-6"/>',
      copy: '<rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/>',
      external: '<path d="M14 4h6v6M20 4l-9 9M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/>',
      back: '<path d="M19 12H5M12 19l-7-7 7-7"/>',
      download: '<path d="M12 3v12M6 11l6 6 6-6M4 21h16"/>',
      duplicate: '<rect x="8" y="8" width="12" height="12" rx="2"/>' \
                 '<path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>'
    }.freeze

    # Wraps an admin view in the engine's shell (assets, nav, flash). The block
    # is captured here, in the view's own context, so its lazy `t('.key')`
    # lookups resolve against the view — inside `render layout:` they would
    # resolve against the shell partial instead.
    def fb_admin_shell(&)
      render 'formblocks/shared/admin', content: capture(&)
    end

    # True for a stored attachment — not one that was just assigned and then
    # refused by validation, which has no URL yet.
    def fb_stored?(attachment)
      Formblocks.attachments? && attachment.attached? && attachment.blob&.persisted?
    end

    # Stylesheet and module script for a bundle (:admin or :public), with
    # fingerprinted same-origin URLs served by the engine itself.
    def formblocks_assets(bundle)
      stylesheet = stylesheet_link_tag(formblocks_asset_url("#{bundle}.css"), 'data-turbo-track': 'reload')
      script = javascript_include_tag(formblocks_asset_url("#{bundle}.js"), type: 'module',
                                                                            'data-turbo-track': 'reload', nonce: true)
      safe_join([stylesheet, script], "\n")
    end

    def formblocks_asset_url(name)
      formblocks.engine_asset_path(name, v: Formblocks::Assets.fingerprint(name))
    end

    # A nonced <style> setting the brand custom properties, so no element
    # needs an inline style attribute (which a strict style-src refuses).
    # The colors are validated on save; this re-checks them on the way into
    # a <style> tag, so nothing but a hex color can ever land there.
    def formblocks_brand_style(form)
      primary = fb_hex_color(form.effective_primary_color, Formblocks::Configuration.new.default_primary_color)
      text = fb_hex_color(form.effective_button_text_color, Formblocks::Configuration.new.default_button_text_color)
      css = ".fb-brand { --fb-primary: #{primary}; --fb-primary-text: #{text}; }"
      content_tag(:style, css.html_safe, nonce: content_security_policy_nonce) # rubocop:disable Rails/OutputSafety
    end

    def fb_hex_color(value, fallback)
      value.to_s.match?(Formblocks::Form::COLOR_FORMAT) ? value.to_s : fallback
    end

    def fb_icon(name, **options)
      body = ICONS.fetch(name)
      options[:class] = ['fb-icon', options[:class]].compact.join(' ')
      tag.svg(body.html_safe, # rubocop:disable Rails/OutputSafety
              viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2',
              'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'aria-hidden': 'true', **options)
    end

    # An answer as the dashboard shows it: a small thumbnail linking to the
    # full image when a URL answer points at a picture, else the block's text.
    def fb_answer(block, value)
      return block.display_answer(value) unless block.respond_to?(:image_answer?) && block.image_answer?(value)

      link_to(value, target: '_blank', rel: 'noopener', class: 'fb-answer-thumb-link', title: value) do
        image_tag(value, class: 'fb-answer-thumb', alt: '', loading: 'lazy')
      end
    end

    def fb_status_badge(form)
      tag.span(t("formblocks.status.#{form.status}"), class: "fb-badge fb-badge--#{form.status}")
    end

    # Where visitors reach the form.
    def fb_public_url(form, **)
      main_app.formblocks_form_url(form.slug, **)
    end

    def fb_public_base_url
      "#{request.base_url}#{Formblocks.config.public_path.to_s.chomp('/')}"
    end

    # Attachments are served by the host's Active Storage routes.
    def fb_attachment_url(attachment)
      main_app.url_for(attachment)
    end

    def fb_time(time)
      tag.time(l(time, format: :short), datetime: time.iso8601, title: l(time, format: :long))
    end
  end
end
