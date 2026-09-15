# frozen_string_literal: true

module Formblocks
  module Generators
    # Shared bits every migration-writing generator needs.
    module MigrationHelpers
      private

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      # Follow the host's own key type instead of forcing bigint. An app that
      # keys its models with uuids sets this, and its
      # `active_storage_attachments.record_id` is then a uuid column — bigint
      # tables here could never take a logo or image attachment.
      #
      # Same lookup Rails' own Active Storage, Action Text and Action Mailbox
      # migrations do, so a host that set it once gets consistent tables from
      # all of them. Rendered as a `create_table` option rather than a bare
      # value, because a template is expanded at generate time.
      def primary_key_type_option
        type = primary_key_type
        type ? ", id: :#{type}" : ''
      end

      # The matching option for `t.references`, so foreign keys point at the
      # right column type.
      def foreign_key_type_option
        type = primary_key_type
        type ? ", type: :#{type}" : ''
      end

      def primary_key_type
        config = Rails.configuration.generators
        config.options[config.orm][:primary_key_type]
      end
    end
  end
end
