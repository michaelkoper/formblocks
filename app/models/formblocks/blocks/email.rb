# frozen_string_literal: true

module Formblocks
  module Blocks
    class Email < Text
      FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

      def self.autocomplete = 'email'

      def html_input_type
        'email'
      end

      def normalize_answer(value)
        super.downcase
      end

      def validate_present_answer(value, errors)
        errors.add(key.to_sym, I18n.t('formblocks.errors.invalid_email')) unless value.to_s.match?(FORMAT)
      end
    end
  end
end
