# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'
require_relative '../migration_helpers'

module Formblocks
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      include MigrationHelpers

      source_root File.expand_path('templates', __dir__)

      desc 'Installs formblocks: config initializer, migration, and routes.'

      class_option :mount_path, type: :string, default: '/forms',
                                desc: 'Where the admin (builder, responses, settings) is mounted'
      class_option :public_path, type: :string, default: '/f',
                                 desc: 'Where published forms are served'

      def create_initializer
        template 'initializer.rb.tt', 'config/initializers/formblocks.rb'
      end

      def create_migration_file
        migration_template 'create_formblocks_tables.rb.tt',
                           'db/migrate/create_formblocks_tables.rb'
      end

      def mount_engine
        route %(mount_formblocks at: "#{options[:mount_path]}", public_at: "#{options[:public_path]}")
      end

      def post_install
        say "\nformblocks installed. Run `bin/rails db:migrate`.", :green
        say "Build forms at #{options[:mount_path]} (development only until you set config.authorize_admin)."
        say "Published forms are served at #{options[:public_path]}/<slug>."
        say "Logo and image uploads need Active Storage: `bin/rails active_storage:install` if you have not.\n"
      end
    end
  end
end
