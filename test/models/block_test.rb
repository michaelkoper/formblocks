# frozen_string_literal: true

require 'test_helper'

# A host-defined block, registered in one test below.
class RatingBlock < Formblocks::Blocks::Input
end

module Formblocks
  class BlockTest < ActiveSupport::TestCase
    setup do
      @form = create_form
      @page = @form.steps.first
    end

    test 'the registry lists every built-in kind in palette order' do
      assert_equal %w[heading paragraph image name email phone url text textarea hidden checkbox radio_group],
                   Block.kinds
      assert_equal %w[heading paragraph image], Block.content_registry.map(&:kind)
      assert_equal Blocks::Email, Block.find_kind('email')
    end

    test 'find_kind raises for an unknown kind' do
      assert_raises(ArgumentError) { Block.find_kind('nope') }
    end

    test 'a host can register its own block class' do
      Block.register('RatingBlock')

      assert_equal RatingBlock, Block.find_kind('rating_block')
      assert_equal 'Rating block', RatingBlock.display_name
      block = @page.blocks.create!(type: 'RatingBlock', label: 'Rate us')
      assert_equal 'rate_us', block.key
    ensure
      Block.registered_types = Block.registered_types - ['RatingBlock']
    end

    test 'an input gets a key from its label, unique within the whole form' do
      first = add_block(@form, 'email', label: 'Work email')
      second = add_block(@form, 'email', label: 'Work email')
      other_page = @form.pages.create!(kind: 'step')
      third = add_block(@form, 'text', page: other_page, label: 'Work email')

      assert_equal %w[work_email work_email_2 work_email_3], [first, second, third].map(&:key)
    end

    test 'the key does not change when the label does' do
      block = add_block(@form, 'email')
      block.update!(label: 'Your email address')

      assert_equal 'email', block.key
    end

    test 'keys are normalized, validated and unique' do
      block = add_block(@form, 'hidden', key: 'UTM Source')
      assert_equal 'utm_source', block.key

      add_block(@form, 'email')
      block.key = 'email'
      assert_not block.valid?
      assert_predicate block.errors[:key], :any?

      block.key = ''
      assert_predicate block, :valid?
      assert_equal 'hidden_field', block.key
    end

    test 'inputs need a label; hidden fields and content blocks do not' do
      assert_not @page.blocks.build(type: 'Formblocks::Blocks::Email').valid?
      assert_predicate @page.blocks.build(type: 'Formblocks::Blocks::Hidden'), :valid?
      assert_predicate @page.blocks.build(type: 'Formblocks::Blocks::Heading'), :valid?
      assert_nil @page.blocks.create!(type: 'Formblocks::Blocks::Heading').key
    end

    test 'only registered, concrete classes can be saved' do
      assert_not Blocks::Input.new(page: @page, label: 'Generic').valid?
      assert_not Block.new(page: @page).valid?
    end

    test 'options_text round-trips and a radio group needs at least one option' do
      block = add_block(@form, 'radio_group')
      assert_equal ['Option 1', 'Option 2', 'Option 3'], block.options
      assert_equal "Option 1\nOption 2\nOption 3", block.options_text

      block.options_text = " A \r\n\r\nB\n"
      assert_equal %w[A B], block.options
      assert_predicate block, :valid?

      block.options_text = "\n"
      assert_not block.valid?
      assert_predicate block.errors[:options], :any?
    end

    test 'capabilities per kind drive the builder and the public page' do
      hidden = Blocks::Hidden
      assert_predicate hidden, :input?
      assert_not hidden.requirable?
      assert_not hidden.placeholder?
      assert_not hidden.new.visible?

      assert_not Blocks::Checkbox.placeholder?
      assert_predicate Blocks::RadioGroup, :options?
      assert_predicate Blocks::Heading, :content?
      assert_predicate Blocks::Image, :image?
      assert_not Blocks::Image.input?

      assert_equal 'formblocks/public/blocks/text', Blocks::Email.new.public_partial
      assert_equal 'formblocks/public/blocks/textarea', Blocks::Textarea.new.public_partial
      assert_equal 'email', Blocks::Email.new.html_input_type
      assert_equal 'email', Blocks::Email.new.autocomplete
      assert_equal 'tel', Blocks::Phone.new.html_input_type
      assert_equal 'url', Blocks::Url.new.html_input_type
      assert_equal 'text', Blocks::Name.new.html_input_type
      assert_equal 'name', Blocks::Name.new.autocomplete
    end

    test 'default attributes give every new block something to show' do
      assert_equal({ label: 'Email' }, Blocks::Email.default_attributes)
      assert_equal({ content: 'Heading' }, Blocks::Heading.default_attributes)
      assert_equal({}, Blocks::Image.default_attributes)
    end

    test 'move swaps neighbouring blocks' do
      a = add_block(@form, 'name')
      b = add_block(@form, 'email')

      b.move('up')
      assert_equal [b, a].map(&:id), @page.blocks.reload.map(&:id)

      b.move('up')
      assert_equal [b, a].map(&:id), @page.blocks.reload.map(&:id)

      b.move('down')
      assert_equal [a, b].map(&:id), @page.blocks.reload.map(&:id)
    end

    test 'validate_answer applies the rules of each kind' do
      errors = -> { ActiveModel::Errors.new(Response.new) }

      email = add_block(@form, 'email', required: true)
      e = errors.call
      email.validate_answer('', e)
      assert_equal ['is required'], e[:email]
      e = errors.call
      email.validate_answer('nope', e)
      assert_equal ['is not a valid email address'], e[:email]
      e = errors.call
      email.validate_answer('ada@example.com', e)
      assert_empty e

      url = add_block(@form, 'url')
      e = errors.call
      url.validate_answer('', e)
      assert_empty e
      url.validate_answer('example.com', e)
      assert_equal ['is not a valid URL (include http:// or https://)'], e[:url]
      e = errors.call
      url.validate_answer('https://example.com/x', e)
      assert_empty e

      radio = add_block(@form, 'radio_group', options: %w[A B])
      e = errors.call
      radio.validate_answer('Z', e)
      assert_equal ['is not one of the options'], e[:radio_group]

      checkbox = add_block(@form, 'checkbox', required: true)
      e = errors.call
      checkbox.validate_answer(false, e)
      assert_equal ['must be checked'], e[:checkbox]

      text = add_block(@form, 'text')
      e = errors.call
      text.validate_answer('x' * 10_001, e)
      assert_equal ['is too long'], e[:short_text]
    end

    test 'normalize_answer and display_answer' do
      email = add_block(@form, 'email')
      assert_equal 'ada@example.com', email.normalize_answer('  ADA@Example.com ')

      checkbox = add_block(@form, 'checkbox')
      assert_equal true, checkbox.normalize_answer('1')
      assert_equal false, checkbox.normalize_answer('0')
      assert_equal false, checkbox.normalize_answer(nil)
      assert_equal 'Yes', checkbox.display_answer(true)
      assert_equal 'No', checkbox.display_answer(false)

      text = add_block(@form, 'text')
      assert_equal 'hi', text.normalize_answer(" hi\n")
      assert_equal '', text.normalize_answer(nil)
    end

    test 'a hidden field has a default value from its content' do
      hidden = add_block(@form, 'hidden', key: 'source', content: 'direct')

      assert_equal 'direct', hidden.default_value
    end

    test 'the image must be an image' do
      block = add_block(@form, 'image')
      block.image.attach(io: StringIO.new('nope'), filename: 'a.txt', content_type: 'text/plain')

      assert_not block.valid?
      assert_predicate block.errors[:image], :any?
    end
  end
end
