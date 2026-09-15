# frozen_string_literal: true

module Formblocks
  module Blocks
    # Pick one of several options.
    class RadioGroup < Input
      def self.options? = true
      def self.placeholder? = false

      def self.default_attributes
        { label: display_name,
          options: (1..3).map { |n| I18n.t('formblocks.blocks.defaults.option', n:) } }
      end

      validate :options_present

      def validate_present_answer(value, errors)
        errors.add(key.to_sym, I18n.t('formblocks.errors.invalid_option')) unless Array(options).include?(value)
      end

      private

      def options_present
        errors.add(:options, :blank) if Array(options).compact_blank.empty?
      end
    end
  end
end
