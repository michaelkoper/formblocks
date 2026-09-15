# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class AdminSettingsTest < ActionDispatch::IntegrationTest
    setup { as_admin! }

    test 'show renders the brand fields with the configured defaults as placeholders' do
      get '/forms/settings'

      assert_response :success
      assert_select 'input[name="setting[primary_color]"][placeholder="#111827"]'
      assert_select 'input[name="setting[button_text_color]"][placeholder="#ffffff"]'
      assert_select 'input[type=file][name="setting[logo]"]'
      assert_select '.fb-nav__link.is-active', text: 'Settings'
    end

    test 'update saves the colors for the tenant' do
      Formblocks.config.tenant = ->(_request) { 'acme' }

      patch '/forms/settings', params: { setting: { primary_color: '#00FF00', button_text_color: '#000000' } }

      assert_redirected_to '/forms/settings'
      setting = Setting.find_by!(tenant: 'acme')
      assert_equal '#00ff00', setting.primary_color
      assert_equal '#000000', setting.button_text_color
      assert_equal '#00ff00', create_form(tenant: 'acme').effective_primary_color
    end

    test 'update rejects a bad color' do
      patch '/forms/settings', params: { setting: { primary_color: 'green' } }

      assert_response :unprocessable_entity
      assert_select '.fb-errors li', text: /Primary color/
      assert_nil Setting.for_tenant(nil).primary_color
    end

    test 'update uploads and removes the global logo' do
      patch '/forms/settings', params: { setting: { logo: png_upload } }
      assert_redirected_to '/forms/settings'
      assert_predicate Setting.for_tenant(nil).logo, :attached?

      patch '/forms/settings', params: { setting: { remove_logo: '1' } }
      assert_not Setting.for_tenant(nil).logo.attached?
    end

    test 'settings are gated' do
      reset_formblocks_config!

      patch '/forms/settings', params: { setting: { primary_color: '#00ff00' } }

      assert_response :forbidden
      assert_equal 0, Setting.count
    end
  end
end
