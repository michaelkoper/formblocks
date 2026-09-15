# frozen_string_literal: true

module Formblocks
  module Blocks
    # Base of every block a visitor answers. Subclasses set the HTML input
    # type, autocomplete hint and validation; the answer is stored in the
    # response's `answers` hash under the block's `key`.
    class Input < Block
      MAX_ANSWER_LENGTH = 10_000

      def self.input? = true
      def self.placeholder? = true
      def self.requirable? = true

      def self.default_attributes
        { label: display_name }
      end

      # The HTML autocomplete token, or nil.
      def self.autocomplete
        nil
      end

      def html_input_type
        'text'
      end

      delegate :autocomplete, to: :class

      def label_required?
        true
      end

      # The submitted value as it is stored.
      def normalize_answer(value)
        value.to_s.strip
      end

      # Adds errors to `errors` under this block's key.
      def validate_answer(value, errors)
        if value.blank?
          errors.add(key.to_sym, I18n.t('formblocks.errors.required')) if required?
        elsif value.to_s.length > MAX_ANSWER_LENGTH
          errors.add(key.to_sym, I18n.t('formblocks.errors.too_long'))
        else
          validate_present_answer(value, errors)
        end
      end

      # Type-specific checks on a non-blank answer.
      def validate_present_answer(_value, _errors); end

      # The answer as the dashboard and CSV show it.
      def display_answer(value)
        value.to_s
      end
    end
  end
end
