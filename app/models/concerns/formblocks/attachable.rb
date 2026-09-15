# frozen_string_literal: true

module Formblocks
  # `attachable :logo` — an Active Storage image attachment with a
  # `remove_logo` flag and size/type validation. A no-op when the host has no
  # Active Storage (or turned attachments off), so the models still load.
  module Attachable
    extend ActiveSupport::Concern

    class_methods do
      def attachable(name)
        return unless Formblocks.attachments?

        has_one_attached name, service: Formblocks.config.storage_service
        attribute :"remove_#{name}", :boolean, default: false

        validate { validate_attachable(name) }
        after_save do
          attachment = public_send(name)
          attachment.purge if public_send(:"remove_#{name}") && attachment.attached?
        end
      end
    end

    private

    # Only a freshly assigned upload is checked; what is already stored was
    # checked when it came in.
    def validate_attachable(name)
      attachment = public_send(name)
      return unless attachment.attached? && attachment.blob&.new_record?

      unless attachment.content_type.to_s.start_with?('image/')
        errors.add(name,
                   I18n.t('formblocks.errors.not_an_image'))
      end
      return if attachment.byte_size.to_i <= Formblocks.config.max_upload_size

      errors.add(name,
                 I18n.t('formblocks.errors.file_too_large', size: Formblocks.config.max_upload_size / (1024 * 1024)))
    end
  end
end
