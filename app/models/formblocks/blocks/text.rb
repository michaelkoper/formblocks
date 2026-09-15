# frozen_string_literal: true

module Formblocks
  module Blocks
    # A single-line text input. Name, Email, Phone and Url specialise it.
    class Text < Input
      def public_partial
        'formblocks/public/blocks/text'
      end
    end
  end
end
