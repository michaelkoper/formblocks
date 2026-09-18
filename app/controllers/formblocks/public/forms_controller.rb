# frozen_string_literal: true

module Formblocks
  module Public
    # The visitor-facing pages: the form, its submission, and the thank-you
    # page. Routed by the host app (see `mount_formblocks`), so URL helpers go
    # through `main_app`.
    class FormsController < Formblocks::ApplicationController
      layout 'formblocks/public'

      before_action :set_form

      # Throttle submissions per IP so one visitor or bot cannot flood the
      # responses. Rails' own limiter, backed by Rails.cache. Tune or disable
      # via config.rate_limit — read once when the controller loads, so set
      # it in an initializer.
      if Formblocks.config.rate_limit
        rate_limit(**Formblocks.config.rate_limit, only: :create, with: -> { render_rate_limited })
      end

      def show
        # The query string only — never the path's own :slug.
        @response = @form.responses.new.prefill(request.query_parameters)
        @referrer = clean_page_url(request.referer)
      end

      def create
        @referrer = clean_page_url(params[:fb_referrer])
        # The honeypot: a field no human sees. Bots fill it; we pretend it
        # worked and save nothing.
        return redirect_to(thanks_path, status: :see_other) if params[:fb_website].present?

        @response = @form.responses.new(page_url: @referrer, user_agent: request.user_agent.to_s.first(500),
                                        locale: I18n.locale.to_s)
        @response.fill(params.fetch(:answers, {}).to_unsafe_h)

        if @response.save
          redirect_to thanks_path, status: :see_other
        else
          render :show, status: :unprocessable_content
        end
      end

      def thanks
        @page = @form.thank_you_page
      end

      private

      # Drafts are visible only to admins previewing them (?preview=1).
      def set_form
        @form = Form.includes(pages: :blocks).find_by(slug: params[:slug])
        return if @form && (@form.published? || preview?)

        render :not_found, status: :not_found
      end

      def preview?
        params[:preview].present? && Formblocks.admin?(request)
      end

      def thanks_path
        main_app.formblocks_form_thanks_path(@form.slug, preview: params[:preview].presence)
      end

      # The form again, answers kept, with the message where the errors go.
      def render_rate_limited
        @referrer = clean_page_url(params[:fb_referrer])
        @response = @form.responses.new.fill(params.fetch(:answers, {}).to_unsafe_h)
        @rate_limited = true
        render :show, status: :too_many_requests
      end
    end
  end
end
