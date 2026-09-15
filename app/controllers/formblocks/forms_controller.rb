# frozen_string_literal: true

module Formblocks
  class FormsController < DashboardController
    before_action :set_form, except: %i[index new create]

    def index
      @forms = tenant_forms.newest_first
    end

    def new
      @templates = Formblocks.config.templates
    end

    # The builder.
    def edit
      @pages = @form.pages.includes(:blocks)
    end

    def create
      template = Formblocks.config.templates[params[:template].to_s] if params[:template].present?
      @form = if template
                Form.from_template(template, tenant: current_tenant)
              else
                Form.new(title: t('formblocks.forms.new.untitled'), tenant: current_tenant)
              end
      @form.save!
      redirect_to edit_form_path(@form), notice: t('formblocks.flash.form_created')
    end

    def settings; end

    def update
      if @form.update(form_params)
        redirect_to settings_form_path(@form), notice: t('formblocks.flash.form_updated'), status: :see_other
      else
        render :settings, status: :unprocessable_content
      end
    end

    def destroy
      @form.destroy!
      redirect_to forms_path, notice: t('formblocks.flash.form_deleted'), status: :see_other
    end

    def duplicate
      copy = @form.duplicate
      redirect_to edit_form_path(copy), notice: t('formblocks.flash.form_duplicated'), status: :see_other
    end

    def publish
      @form.publish!
      redirect_to published_form_path(@form), status: :see_other
    end

    def unpublish
      @form.unpublish!
      redirect_to edit_form_path(@form), notice: t('formblocks.flash.form_unpublished'), status: :see_other
    end

    def published; end

    private

    def form_params
      permitted = %i[title slug primary_color button_text_color]
      permitted += %i[logo remove_logo] if Formblocks.attachments?
      params.expect(form: [*permitted])
    end
  end
end
