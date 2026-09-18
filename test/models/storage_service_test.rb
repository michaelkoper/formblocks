# frozen_string_literal: true

require 'test_helper'

# `config.storage_service` names the Active Storage service every upload —
# form logo, global logo, image blocks — is stored on. The concern reads it
# when a model class loads, which is after the host's initializers ran.
module Formblocks
  class StorageServiceTest < ActiveSupport::TestCase
    # The models read the config as they load. Load the real ones first, so a
    # test that changes it cannot be what autoloads them, whatever the order.
    setup { [Form, Setting, Block].each(&:name) }

    test 'every attachment uses the app default service by default' do
      assert_nil Form.attachment_reflections['logo'].options[:service_name]
      assert_nil Setting.attachment_reflections['logo'].options[:service_name]
      assert_nil Block.attachment_reflections['image'].options[:service_name]

      form = create_form
      form.logo.attach(io: StringIO.new(PNG), filename: 'logo.png', content_type: 'image/png')

      assert_equal 'test', form.logo.blob.service_name
    end

    test 'storage_service routes uploads to the named service' do
      Formblocks.config.storage_service = :formblocks_uploads
      probe = Formblocks.const_set(:StorageProbe, Class.new(Setting))
      probe.attachable :logo

      assert_equal :formblocks_uploads, probe.attachment_reflections['logo'].options[:service_name]

      setting = probe.new(tenant: 'probe')
      setting.logo.attach(io: StringIO.new(PNG), filename: 'logo.png', content_type: 'image/png')
      setting.save!

      assert_equal 'formblocks_uploads', setting.reload.logo.blob.service_name
      assert_equal PNG, setting.logo.download
    ensure
      Formblocks.send(:remove_const, :StorageProbe) if Formblocks.const_defined?(:StorageProbe, false)
    end

    test 'a service missing from storage.yml fails loudly when the model loads' do
      Formblocks.config.storage_service = :nowhere
      probe = Formblocks.const_set(:StorageProbe, Class.new(Setting))

      error = assert_raises(ArgumentError) { probe.attachable :logo }
      assert_match 'nowhere', error.message
    ensure
      Formblocks.send(:remove_const, :StorageProbe) if Formblocks.const_defined?(:StorageProbe, false)
    end
  end
end
