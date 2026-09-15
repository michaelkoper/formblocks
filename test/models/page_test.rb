# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class PageTest < ActiveSupport::TestCase
    setup do
      @form = create_form
      @form.pages.create!(kind: 'step')
      @form.resequence_pages!
      @first, @second = @form.steps
    end

    test 'the button reads Next on a middle step and Submit on the last, unless customised' do
      assert_equal 'Next', @first.button_label
      assert_equal 'Submit', @second.button_label

      @first.update!(button_text: 'Continue →')
      assert_equal 'Continue →', @first.button_label
      @first.update!(button_text: '')
      assert_equal 'Next', @first.button_label
    end

    test 'number and last_step? follow the step order' do
      assert_equal 1, @first.number
      assert_equal 2, @second.number
      assert_not @first.last_step?
      assert_predicate @second, :last_step?
    end

    test 'move swaps neighbouring steps and keeps the thank-you page last' do
      @second.move('up')

      assert_equal [@second, @first].map(&:id), @form.reload.steps.map(&:id)
      assert_equal 3, @form.thank_you_page.position

      @second.reload.move('up') # already first: nothing happens
      assert_equal [@second, @first].map(&:id), @form.reload.steps.map(&:id)

      @form.thank_you_page.move('up')
      assert_equal 'thank_you', @form.reload.pages.last.kind
    end

    test 'reorder_blocks applies the given order and tolerates unknown ids' do
      a = add_block(@form, 'name')
      b = add_block(@form, 'email')
      c = add_block(@form, 'phone')

      @first.reorder_blocks([c.id, 'bogus', a.id])

      assert_equal [c, a, b].map(&:id), @first.blocks.reload.map(&:id)
      assert_equal [1, 2, 3], @first.blocks.map(&:position)
    end

    test 'the thank-you page allows content blocks only' do
      assert_equal %w[heading paragraph image], @form.thank_you_page.allowed_block_classes.map(&:kind)
      assert_equal Block.kinds, @first.allowed_block_classes.map(&:kind)
    end

    test 'the button text is limited to 60 characters and the kind to the known ones' do
      @first.button_text = 'x' * 61
      assert_not @first.valid?

      @first.button_text = 'x' * 60
      @first.kind = 'nope'
      assert_not @first.valid?
    end

    test 'a new page takes the next position' do
      page = @form.pages.create!(kind: 'step')

      assert_equal 4, page.position
    end
  end
end
