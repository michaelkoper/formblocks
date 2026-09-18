# frozen_string_literal: true

module Formblocks
  module Blocks
    # A field the visitor never sees. `key` is its name, `content` its default
    # value; like any input it can be filled from the public URL's query
    # string (see Response#prefill), so ?utm_source=newsletter lands in the
    # response.
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
