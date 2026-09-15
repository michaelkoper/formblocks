# frozen_string_literal: true

module Formblocks
  # A block on a page: a piece of content (heading, paragraph, image) or an
  # input the visitor answers. Single-table inheritance; every block is a Ruby
  # class under Formblocks::Blocks, and hosts can subclass and register their own:
  #
  #   class Rating < Formblocks::Blocks::Input; end
  #   Formblocks::Block.register 'Rating'
  class Block < ApplicationRecord
    include Attachable

    KEY_FORMAT = /\A[a-z0-9_]+\z/

    belongs_to :page, inverse_of: :blocks, touch: true
    attachable :image

    # The palette, in the order the builder shows it. Class names as strings
    # so they autoload on first use.
    class_attribute :registered_types, instance_writer: false, default: %w[
      Formblocks::Blocks::Heading
      Formblocks::Blocks::Paragraph
      Formblocks::Blocks::Image
      Formblocks::Blocks::Name
      Formblocks::Blocks::Email
      Formblocks::Blocks::Phone
      Formblocks::Blocks::Url
      Formblocks::Blocks::Text
      Formblocks::Blocks::Textarea
      Formblocks::Blocks::Hidden
      Formblocks::Blocks::Checkbox
      Formblocks::Blocks::RadioGroup
    ]

    normalizes :key, with: ->(key) { key.to_s.parameterize(separator: '_').presence }

    before_validation :assign_key, if: :input?
    before_create :assign_position

    validates :type, inclusion: { in: ->(_block) { Block.registered_types } }
    validates :label, presence: true, if: :label_required?
    validates :label, :placeholder, length: { maximum: 200 }
    validates :help_text, length: { maximum: 500 }
    validates :content, length: { maximum: 10_000 }
    validates :key, presence: true, length: { maximum: 60 }, format: { with: KEY_FORMAT }, if: :input?
    validate :key_unique_within_form, if: :input?

    class << self
      # "radio_group" for Formblocks::Blocks::RadioGroup — the identifier used
      # in templates, the palette and partial names.
      def kind
        name.demodulize.underscore
      end

      def registry
        registered_types.map(&:constantize)
      end

      def kinds
        registry.map(&:kind)
      end

      def content_registry
        registry.reject(&:input?)
      end

      def input_registry
        registry.select(&:input?)
      end

      def find_kind(kind)
        registry.find { |klass| klass.kind == kind.to_s } ||
          raise(ArgumentError, "Unknown block kind: #{kind.inspect}")
      end

      def register(class_name)
        Block.registered_types += [class_name.to_s] unless Block.registered_types.include?(class_name.to_s)
      end

      def display_name
        I18n.t("formblocks.blocks.#{kind}.name", default: kind.humanize)
      end

      # Capabilities — what the builder shows and the public page renders.
      def input? = false
      def content? = false
      def options? = false
      def placeholder? = false
      def requirable? = false
      def image? = false

      # Attributes for a block freshly added from the palette.
      def default_attributes
        {}
      end

      # `base`, or `base_2`, `base_3`… until it is not in `taken`.
      def unique_key(base, taken)
        candidate = base
        n = 2
        while taken.include?(candidate)
          candidate = "#{base}_#{n}"
          n += 1
        end
        candidate
      end
    end

    delegate :kind, :input?, :content?, :options?, :placeholder?, :requirable?, :image?, :display_name,
             to: :class

    # Rendered in the visible flow of the public form (hidden fields are not).
    def visible?
      true
    end

    # The partial the public page renders this block with. Subclasses that
    # look alike share one (every single-line text input uses `text`).
    def public_partial
      "formblocks/public/blocks/#{kind}"
    end

    # Swap with the neighbouring block on the same page.
    def move(direction)
      list = page.blocks.reload.to_a
      index = list.index { |block| block.id == id }
      other = direction.to_s == 'up' ? index - 1 : index + 1
      return if index.nil? || other.negative? || other >= list.size

      list[index], list[other] = list[other], list[index]
      transaction do
        list.each_with_index { |block, i| block.update_column(:position, i + 1) }
      end
      page.blocks.reset
    end

    def label_required?
      false
    end

    # Options as the builder edits them: one per line.
    def options_text
      Array(options).join("\n")
    end

    def options_text=(text)
      self.options = text.to_s.lines.map(&:strip).compact_blank
    end

    # The key an input gets when none was given: from the label ("Work email"
    # → "work_email"), else the kind.
    def default_key
      (label.presence || kind).to_s.parameterize(separator: '_').presence || kind
    end

    private

    def assign_key
      self.key = self.class.unique_key(default_key, sibling_keys) if key.blank?
    end

    def sibling_keys
      form = page&.form
      return [] unless form&.persisted?

      form.blocks.where.not(id: id).where.not(key: nil).pluck(:key)
    end

    def key_unique_within_form
      errors.add(:key, :taken) if key.present? && sibling_keys.include?(key)
    end

    def assign_position
      self.position = (page.blocks.maximum(:position) || 0) + 1 if position.to_i.zero? && page&.persisted?
    end
  end
end
