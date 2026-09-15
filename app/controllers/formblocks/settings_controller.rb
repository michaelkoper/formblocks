# frozen_string_literal: true

module Formblocks
  # The tenant's brand defaults, one page.
  class SettingsController < DashboardController
    before_action :set_setting

    def show; end

    def update
      if @setting.update(setting_params)
        redirect_to settings_path, notice: t('formblocks.flash.settings_updated'), status: :see_other
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_setting
      @setting = Setting.for_tenant(current_tenant)
    end

    def setting_params
      permitted = %i[primary_color button_text_color]
      permitted += %i[logo remove_logo] if Formblocks.attachments?
      params.expect(setting: [*permitted])
    end
  end
end
