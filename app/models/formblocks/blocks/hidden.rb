# frozen_string_literal: true

module Formblocks
  module Blocks
    # A field the visitor never sees. `key` is its name, `content` its default
    # value; a query parameter with the same name on the public URL overrides
    # the default, so ?utm_source=newsletter lands in the response.
    class Hidden < Input
      def self.placeholder? = false
      def self.requirable? = false

      def visible?
        false
      end

      def label_required?
        false
      end

      def default_value
        content.to_s
      end
    end
  end
end
