# frozen_string_literal: true

module Formblocks
  module Blocks
    class Heading < Block
      def self.content? = true

      def self.default_attributes
        { content: I18n.t('formblocks.blocks.defaults.heading') }
      end
    end
  end
end
