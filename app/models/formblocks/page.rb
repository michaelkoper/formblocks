# frozen_string_literal: true

module Formblocks
  # One screen of a form. `step` pages hold the blocks a visitor fills in and
  # end in a button; the single `thank_you` page is shown after submission
  # and takes content blocks only.
  class Page < ApplicationRecord
    KINDS = %w[step thank_you].freeze

    belongs_to :form, inverse_of: :pages, touch: true
    has_many :blocks, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :page

    validates :kind, inclusion: { in: KINDS }
    validates :button_text, length: { maximum: 60 }

    before_create :assign_position

    def step?
      kind == 'step'
    end

    def thank_you?
      kind == 'thank_you'
    end

    # 1-based position among the step pages.
    def number
      form.steps.index { |page| page.id == id }.to_i + 1
    end

    def last_step?
      form.steps.last&.id == id
    end

    # The visitor-facing button: the custom text, else "Next" or "Submit".
    def button_label
      button_text.presence || I18n.t(last_step? ? 'formblocks.public.submit' : 'formblocks.public.next')
    end

    # Which block classes the builder may add here.
    def allowed_block_classes
      thank_you? ? Block.content_registry : Block.registry
    end

    # Swap with the neighbouring step. The thank-you page never moves.
    def move(direction)
      return unless step?

      list = form.steps
      index = list.index { |page| page.id == id }
      other = direction.to_s == 'up' ? index - 1 : index + 1
      return if index.nil? || other.negative? || other >= list.size

      list[index], list[other] = list[other], list[index]
      transaction do
        list.each_with_index { |page, i| page.update_column(:position, i + 1) }
        form.thank_you_page&.update_column(:position, list.size + 1)
      end
      form.pages.reset
    end

    # Reorder the blocks to match `ids`; ids that are not on this page are
    # ignored, blocks missing from `ids` keep their relative order at the end.
    def reorder_blocks(ids)
      ids = Array(ids).map(&:to_s)
      ordered = blocks.reload.sort_by.with_index { |block, i| [ids.index(block.id.to_s) || ids.size, i] }
      transaction do
        ordered.each_with_index { |block, i| block.update_column(:position, i + 1) }
      end
      blocks.reset
    end

    private

    def assign_position
      self.position = (form.pages.maximum(:position) || 0) + 1 if position.to_i.zero? && form&.persisted?
    end
  end
end
