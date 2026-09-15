# frozen_string_literal: true

module Formblocks
  module Blocks
    # A single yes/no checkbox. Required means it must be ticked.
    class Checkbox < Input
      def self.placeholder? = false

      def normalize_answer(value)
        ActiveModel::Type::Boolean.new.cast(value) ? true : false
      end

      def validate_answer(value, errors)
        errors.add(key.to_sym, I18n.t('formblocks.errors.must_be_checked')) if required? && !value
      end

      def display_answer(value)
        I18n.t(value ? 'formblocks.blocks.defaults.yes' : 'formblocks.blocks.defaults.no')
      end
    end
  end
end
