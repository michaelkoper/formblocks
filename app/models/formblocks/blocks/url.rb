# frozen_string_literal: true

require 'uri'

module Formblocks
  module Blocks
    class Url < Text
      # A URL the dashboard can show as a picture: an image file extension, or
      # an image delivery path in the Cloudinary style (/image/upload/).
      IMAGE_URL = %r{\Ahttps?://\S+(?:\.(?:png|jpe?g|gif|webp|avif|svg)(?:\?\S*)?\z|/image/upload/)}i

      def self.autocomplete = 'url'

      def html_input_type
        'url'
      end

      # True when the stored answer is a link to an image.
      def image_answer?(value)
        value.to_s.match?(IMAGE_URL)
      end

      def validate_present_answer(value, errors)
        uri = begin
          URI.parse(value.to_s)
        rescue URI::InvalidURIError
          nil
        end
        return if uri.is_a?(URI::HTTP) && uri.host.present?

        errors.add(key.to_sym, I18n.t('formblocks.errors.invalid_url'))
      end
    end
  end
end
