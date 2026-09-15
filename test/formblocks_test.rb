# frozen_string_literal: true

require 'test_helper'

class FormblocksTest < ActiveSupport::TestCase
  test 'has a version' do
    assert_match(/\A\d+\.\d+\.\d+\z/, Formblocks::VERSION)
  end

  test 'the configuration has safe defaults' do
    config = Formblocks.config

    assert_equal 'ActionController::Base', config.base_controller_class
    assert_equal 'formblocks/application', config.admin_layout
    assert_equal '/forms', config.mount_path
    assert_equal '/f', config.public_path
    assert_equal '#111827', config.default_primary_color
    assert_equal '#ffffff', config.default_button_text_color
    assert_equal({ to: 10, within: 60 }, config.rate_limit)
    assert config.attachments
    assert_equal %w[contact lead feedback], config.templates.keys
  end

  test 'app_name falls back to the Rails application name' do
    assert_equal 'Dummy', Formblocks.app_name

    Formblocks.config.app_name = 'Nusii'
    assert_equal 'Nusii', Formblocks.app_name

    Formblocks.config.app_name = ''
    assert_equal 'Dummy', Formblocks.app_name
  end

  test 'the admin gate is development-only by default' do
    request = ActionDispatch::TestRequest.create

    assert_not Formblocks.admin?(request)
    as_admin!
    assert Formblocks.admin?(request)
  end

  test 'the tenant is normalized to a string, blank to nil' do
    request = ActionDispatch::TestRequest.create

    assert_nil Formblocks.tenant(request)
    Formblocks.config.tenant = ->(_request) { 42 }
    assert_equal '42', Formblocks.tenant(request)
    Formblocks.config.tenant = ->(_request) { '' }
    assert_nil Formblocks.tenant(request)
  end

  test '.for scopes forms to a host record by GlobalID' do
    owner = create_form(title: 'Owner')
    mine = create_form(title: 'Mine', tenant: owner.to_gid.to_s)
    create_form(title: 'Other', tenant: 'other')

    assert_equal [mine], Formblocks.for(owner).to_a
  end

  test 'attachments need Active Storage and the config switch' do
    assert_predicate Formblocks, :attachments?
    Formblocks.config.attachments = false
    assert_not Formblocks.attachments?
  end

  test 'templates can be added and removed by the host' do
    Formblocks.config.templates['webinar'] =
      { title: 'Webinar', pages: [{ blocks: [{ type: 'email', label: 'Email' }] }] }
    Formblocks.config.templates.delete('feedback')

    assert_equal %w[contact lead webinar], Formblocks.config.templates.keys
    form = Formblocks::Form.from_template(Formblocks.config.templates['webinar'])
    form.save!
    assert_equal %w[email], form.input_blocks.map(&:key)
  end
end
