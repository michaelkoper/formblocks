# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require_relative 'dummy/config/environment'
ActiveRecord::Migrator.migrations_paths = [File.expand_path('dummy/db/migrate', __dir__)]
require 'rails/test_help'
require 'rack/test'
require 'base64'

module FormblocksTestHelpers
  # A 1×1 transparent PNG, for upload tests.
  PNG = Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5E' \
                        'rkJggg==')

  # Start every test from a fresh config. The dummy mounts the admin at /forms
  # and the public pages at /f, so keep those two in step with its routes.
  def reset_formblocks_config!
    Formblocks.instance_variable_set(:@config, Formblocks::Configuration.new)
    Formblocks.config.mount_path = '/forms'
    Formblocks.config.public_path = '/f'
  end

  # Most admin tests need an admin; the default gate is development-only.
  def as_admin!
    Formblocks.config.authorize_admin = ->(_request) { true }
  end

  def create_form(title: 'Contact', tenant: nil, template: nil, publish: false)
    form = if template
             Formblocks::Form.from_template(Formblocks.config.templates.fetch(template), tenant:)
           else
             Formblocks::Form.new(title:, tenant:)
           end
    form.save!
    form.publish! if publish
    form
  end

  # Adds a block of `kind` with its palette defaults to the form's first step.
  def add_block(form, kind, page: nil, **attrs)
    klass = Formblocks::Block.find_kind(kind)
    (page || form.steps.first).blocks.create!(klass.default_attributes.merge(type: klass.name).merge(attrs))
  end

  def turbo_headers
    { 'Accept' => 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml' }
  end

  def png_upload(name = 'logo.png')
    Rack::Test::UploadedFile.new(StringIO.new(PNG), 'image/png', original_filename: name)
  end

  def text_upload
    Rack::Test::UploadedFile.new(StringIO.new('hello'), 'text/plain', original_filename: 'notes.txt')
  end
end

module ActiveSupport
  class TestCase
    include FormblocksTestHelpers

    setup do
      reset_formblocks_config!
      Rails.cache.clear
    end
  end
end
