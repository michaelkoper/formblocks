# frozen_string_literal: true

require 'test_helper'

# `config.base_controller_class` reparents the ADMIN only. The split is the
# safety property: if the public form pages shared a controller with the
# admin, pointing this at a host's admin controller would demand a staff
# session from every visitor filling in a form.
module Formblocks
  class BaseControllerTest < ActionDispatch::IntegrationTest
    test 'defaults to a plain ActionController::Base' do
      assert_equal 'ActionController::Base', Formblocks.config.base_controller_class
      assert_equal ActionController::Base, Formblocks.base_controller
    end

    test 'resolves the host class lazily, by name' do
      Formblocks.config.base_controller_class = 'HostAdminBaseController'

      assert_equal HostAdminBaseController, Formblocks.base_controller
    end

    # The superclass is fixed when the class body runs, so this asserts the
    # wiring rather than reparenting a loaded constant mid-process.
    test 'the admin hangs off the configured base controller' do
      assert_equal Formblocks.base_controller, DashboardController.superclass
      [FormsController, PagesController, BlocksController, ResponsesController, SettingsController].each do |controller|
        assert_equal DashboardController, controller.superclass
      end
    end

    test 'the public controllers stay off the host base controller' do
      assert_equal ActionController::Base, Formblocks::ApplicationController.superclass
      assert_equal Formblocks::ApplicationController, Public::FormsController.superclass
      assert_equal Formblocks::ApplicationController, AssetsController.superclass
    end

    test 'the admin uses its own layout by default' do
      as_admin!

      get '/forms'

      assert_select 'body.fb-page'
      assert_select 'nav.fb-nav'
    end

    test 'a host layout can wrap the admin' do
      as_admin!
      Formblocks.config.admin_layout = 'host_admin'

      get '/forms'

      assert_response :success
      assert_select '#host-admin-nav'
      assert_select 'body.fb-page', count: 0
      # The shell and its assets come from the views, so they survive the swap.
      assert_select 'nav.fb-nav'
      assert_select 'link[href^="/forms/assets/admin.css"]'
    end

    test 'the public routes are drawn on the host app and the admin on the engine' do
      assert_equal '/f/x', Rails.application.routes.url_helpers.formblocks_form_path('x')
      assert_equal '/f/x/thanks', Rails.application.routes.url_helpers.formblocks_form_thanks_path('x')
      assert_equal '/forms', Rails.application.routes.url_helpers.formblocks_path

      engine = Engine.routes
      assert_equal({ controller: 'formblocks/settings', action: 'update' },
                   engine.recognize_path('/settings', method: :patch))
      assert_equal({ controller: 'formblocks/forms', action: 'new' }, engine.recognize_path('/new', method: :get))
      assert_equal({ controller: 'formblocks/forms', action: 'update', id: '12' },
                   engine.recognize_path('/12', method: :patch))
      assert_equal({ controller: 'formblocks/assets', action: 'show', name: 'admin.css' },
                   engine.recognize_path('/assets/admin.css', method: :get))
    end
  end
end
