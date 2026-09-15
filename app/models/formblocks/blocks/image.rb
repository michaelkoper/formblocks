# frozen_string_literal: true

module Formblocks
  module Blocks
    # An uploaded image. `label` doubles as the alt text.
    class Image < Block
      def self.image? = true

      def image_attached?
        Formblocks.attachments? && image.attached?
      end
    end
  end
end
