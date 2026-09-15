# frozen_string_literal: true

require 'uri'

module Formblocks
  module Blocks
    class Url < Text
      def self.autocomplete = 'url'

      def html_input_type
        'url'
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
