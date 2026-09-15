# frozen_string_literal: true

require 'test_helper'
require 'rails/generators/test_case'
require 'generators/formblocks/install/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Formblocks::Generators::InstallGenerator
  destination File.expand_path('../tmp/generator', __dir__)
  setup :prepare_destination
  setup :write_routes

  test 'writes the initializer, the migration and the routes' do
    run_generator

    assert_migration 'db/migrate/create_formblocks_tables.rb' do |migration|
      %w[formblocks_settings formblocks_forms formblocks_pages formblocks_blocks formblocks_responses].each do |table|
        assert_match "create_table :#{table}", migration
      end
      assert_match 'add_index :formblocks_forms, :slug, unique: true', migration
      assert_match 'foreign_key: { to_table: :formblocks_forms }', migration
      assert_no_match 'active_storage', migration
      assert_ruby_file migration
    end

    assert_file 'config/initializers/formblocks.rb' do |initializer|
      assert_match 'Formblocks.configure do |config|', initializer
      assert_match '# config.authorize_admin', initializer
      assert_match '# config.mount_path = "/forms"', initializer
      assert_match '# config.public_path = "/f"', initializer
      assert_ruby_file initializer
    end

    assert_file 'config/routes.rb', %r{mount_formblocks at: "/forms", public_at: "/f"}
  end

  test 'the paths are options' do
    run_generator %w[--mount-path=/admin/forms --public-path=/forms]

    assert_file 'config/routes.rb', %r{mount_formblocks at: "/admin/forms", public_at: "/forms"}
    assert_file 'config/initializers/formblocks.rb', %r{# config.public_path = "/forms"}
  end

  test 'the tables follow the host generators primary_key_type' do
    with_primary_key_type(:uuid) do
      run_generator

      assert_migration 'db/migrate/create_formblocks_tables.rb' do |migration|
        assert_match 'create_table :formblocks_forms, id: :uuid', migration
        assert_match 't.references :form, null: false, type: :uuid, foreign_key: { to_table: :formblocks_forms }',
                     migration
        assert_no_match 'primary_key_type', migration
      end
    end
  end

  test 'the tables take no id option when the host sets nothing' do
    with_primary_key_type(nil) do
      run_generator

      assert_migration 'db/migrate/create_formblocks_tables.rb' do |migration|
        assert_match 'create_table :formblocks_forms do |t|', migration
        assert_match 't.references :form, null: false, foreign_key: { to_table: :formblocks_forms }', migration
      end
    end
  end

  private

  def assert_ruby_file(source)
    assert RubyVM::InstructionSequence.compile(source), 'generated file is not valid Ruby'
  end

  def write_routes
    FileUtils.mkdir_p(File.join(destination_root, 'config'))
    File.write(File.join(destination_root, 'config/routes.rb'), "Rails.application.routes.draw do\nend\n")
  end

  def with_primary_key_type(type)
    config = Rails.configuration.generators
    previous = config.options[config.orm][:primary_key_type]
    config.options[config.orm][:primary_key_type] = type
    yield
  ensure
    config.options[config.orm][:primary_key_type] = previous
  end
end
