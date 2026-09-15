# frozen_string_literal: true

module Formblocks
  module Blocks
    class Phone < Text
      def self.autocomplete = 'tel'

      def html_input_type
        'tel'
      end
    end
  end
end
