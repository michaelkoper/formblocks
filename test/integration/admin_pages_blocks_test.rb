# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class AdminPagesBlocksTest < ActionDispatch::IntegrationTest
    setup do
      as_admin!
      @form = create_form
      @page = @form.steps.first
    end

    def blocks_path(page = @page)
      "/forms/#{@form.id}/pages/#{page.id}/blocks"
    end

    test 'add page inserts a step before the thank-you page' do
      post "/forms/#{@form.id}/pages"
      page = Page.last

      assert_redirected_to "/forms/#{@form.id}/edit#page_#{page.id}"
      assert_equal %w[step step thank_you], @form.reload.pages.map(&:kind)
      assert_equal [1, 2, 3], @form.pages.map(&:position)
    end

    test 'a step can be deleted unless it is the last one; the thank-you page never' do
      post "/forms/#{@form.id}/pages"
      second = Page.last

      delete "/forms/#{@form.id}/pages/#{second.id}"
      assert_redirected_to "/forms/#{@form.id}/edit"
      assert_equal %w[step thank_you], @form.reload.pages.map(&:kind)

      delete "/forms/#{@form.id}/pages/#{@page.id}"
      assert_equal %w[step thank_you], @form.reload.pages.map(&:kind)

      delete "/forms/#{@form.id}/pages/#{@form.thank_you_page.id}"
      assert_equal %w[step thank_you], @form.reload.pages.map(&:kind)
    end

    test 'move page swaps step pages' do
      post "/forms/#{@form.id}/pages"
      second = Page.last

      patch "/forms/#{@form.id}/pages/#{second.id}/move", params: { direction: 'up' }

      assert_redirected_to "/forms/#{@form.id}/edit#page_#{second.id}"
      assert_equal [second.id, @page.id], @form.reload.steps.map(&:id)
      assert_equal 'thank_you', @form.pages.last.kind
    end

    test 'every kind can be added to a step with its defaults' do
      Block.kinds.each do |kind|
        post "#{blocks_path}?kind=#{kind}"
        assert_response :see_other, kind
      end
      blocks = @page.blocks.reload

      assert_equal Block.kinds, blocks.map(&:kind)
      assert_equal (1..blocks.size).to_a, blocks.map(&:position)
      email = blocks.find { |b| b.kind == 'email' }
      assert_equal 'Email', email.label
      assert_equal 'email', email.key
      assert_equal ['Option 1', 'Option 2', 'Option 3'], blocks.find { |b| b.kind == 'radio_group' }.options
      assert_equal 'Heading', blocks.find { |b| b.kind == 'heading' }.content
      assert_redirected_to "/forms/#{@form.id}/edit##{ActionView::RecordIdentifier.dom_id(blocks.last)}"
    end

    test 'inputs cannot be added to the thank-you page' do
      thank_you = @form.thank_you_page

      post "#{blocks_path(thank_you)}?kind=email"
      assert_response :unprocessable_entity

      post "#{blocks_path(thank_you)}?kind=heading"
      assert_response :see_other
      assert_equal %w[heading paragraph heading], thank_you.blocks.reload.map(&:kind)
    end

    test 'an unknown kind is a bad request' do
      post "#{blocks_path}?kind=nope"

      assert_response :bad_request
    end

    test 'update autosaves through Turbo with 204 and keeps the key' do
      block = add_block(@form, 'email')

      attrs = { label: 'Work email', placeholder: 'you@company.com', help_text: 'We reply within a day.',
                required: '1' }
      patch "#{blocks_path}/#{block.id}", headers: turbo_headers, params: { block: attrs }

      assert_response :no_content
      block.reload
      assert_equal 'Work email', block.label
      assert_equal 'you@company.com', block.placeholder
      assert_equal 'We reply within a day.', block.help_text
      assert_predicate block, :required?
      assert_equal 'email', block.key
    end

    test 'update without Turbo redirects back to the builder' do
      block = add_block(@form, 'heading')

      patch "#{blocks_path}/#{block.id}", params: { block: { content: 'Hello there' } }

      assert_redirected_to "/forms/#{@form.id}/edit##{ActionView::RecordIdentifier.dom_id(block)}"
      assert_equal 'Hello there', block.reload.content
    end

    test 'an invalid update re-renders the block card with its errors' do
      block = add_block(@form, 'email')

      patch "#{blocks_path}/#{block.id}", headers: turbo_headers, params: { block: { label: '' } }

      assert_response :unprocessable_entity
      assert_equal 'text/vnd.turbo-stream.html', response.media_type
      assert_match %(<turbo-stream action="replace" target="#{ActionView::RecordIdentifier.dom_id(block)}">),
                   response.body
      assert_match 'Label can&#39;t be blank', response.body
      assert_match 'name="block[label]"', response.body
      assert_equal 'Email', block.reload.label

      patch "#{blocks_path}/#{block.id}", params: { block: { label: '' } }
      assert_redirected_to "/forms/#{@form.id}/edit##{ActionView::RecordIdentifier.dom_id(block)}"
      assert_equal "Label can't be blank", flash[:alert]
    end

    test 'a hidden field’s name can be changed and must stay unique' do
      hidden = add_block(@form, 'hidden')
      add_block(@form, 'email')

      patch "#{blocks_path}/#{hidden.id}", headers: turbo_headers,
                                           params: { block: { key: 'UTM Source', content: 'newsletter' } }
      assert_response :no_content
      assert_equal 'utm_source', hidden.reload.key
      assert_equal 'newsletter', hidden.content

      patch "#{blocks_path}/#{hidden.id}", headers: turbo_headers, params: { block: { key: 'email' } }
      assert_response :unprocessable_entity
      assert_equal 'utm_source', hidden.reload.key
    end

    test 'options_text sets the options of a radio group' do
      radio = add_block(@form, 'radio_group')

      patch "#{blocks_path}/#{radio.id}", headers: turbo_headers,
                                          params: { block: { options_text: "Small\nMedium\n\nLarge\n" } }

      assert_response :no_content
      assert_equal %w[Small Medium Large], radio.reload.options
    end

    test 'destroy removes the block through a Turbo Stream, or redirects' do
      first = add_block(@form, 'email')
      second = add_block(@form, 'name')

      delete "#{blocks_path}/#{first.id}", headers: turbo_headers
      assert_response :success
      assert_match %(<turbo-stream action="remove" target="#{ActionView::RecordIdentifier.dom_id(first)}">),
                   response.body

      delete "#{blocks_path}/#{second.id}"
      assert_redirected_to "/forms/#{@form.id}/edit#page_#{@page.id}"
      assert_empty @page.blocks.reload
    end

    test 'move block swaps neighbours' do
      a = add_block(@form, 'name')
      b = add_block(@form, 'email')

      patch "#{blocks_path}/#{b.id}/move", params: { direction: 'up' }

      assert_redirected_to "/forms/#{@form.id}/edit##{ActionView::RecordIdentifier.dom_id(b)}"
      assert_equal [b, a].map(&:id), @page.blocks.reload.map(&:id)
    end

    test 'reorder takes the ids as JSON, the way the drag-and-drop controller sends them' do
      a = add_block(@form, 'name')
      b = add_block(@form, 'email')
      c = add_block(@form, 'phone')

      patch "#{blocks_path}/reorder", params: { ids: [c.id, a.id, b.id] }.to_json,
                                      headers: { 'Content-Type' => 'application/json' }.merge(turbo_headers)

      assert_response :no_content
      assert_equal [c, a, b].map(&:id), @page.blocks.reload.map(&:id)
    end

    test 'an image block takes an upload and re-renders its card' do
      image = add_block(@form, 'image')

      patch "#{blocks_path}/#{image.id}", headers: turbo_headers,
                                          params: { block: { image: png_upload('photo.png'), label: 'Our office' } }

      assert_response :success
      assert_equal 'text/vnd.turbo-stream.html', response.media_type
      assert_match '<turbo-stream action="replace"', response.body
      assert_match '<img', response.body
      assert_predicate image.reload.image, :attached?
      assert_equal 'Our office', image.label

      patch "#{blocks_path}/#{image.id}", headers: turbo_headers, params: { block: { remove_image: '1' } }
      assert_response :success
      assert_not image.reload.image.attached?
    end

    test 'a non-image upload on an image block is refused' do
      image = add_block(@form, 'image')

      patch "#{blocks_path}/#{image.id}", headers: turbo_headers, params: { block: { image: text_upload } }

      assert_response :unprocessable_entity
      assert_not image.reload.image.attached?
    end

    test 'the page button text autosaves' do
      patch "/forms/#{@form.id}/pages/#{@page.id}", headers: turbo_headers, params: { page: { button_text: 'Send it' } }
      assert_response :no_content
      assert_equal 'Send it', @page.reload.button_text

      patch "/forms/#{@form.id}/pages/#{@page.id}", params: { page: { button_text: '' } }
      assert_redirected_to "/forms/#{@form.id}/edit#page_#{@page.id}"
      assert_equal 'Submit', @page.reload.button_label

      patch "/forms/#{@form.id}/pages/#{@page.id}", headers: turbo_headers, params: { page: { button_text: 'x' * 61 } }
      assert_response :unprocessable_entity
    end

    test 'pages and blocks of another tenant’s form are not reachable' do
      Formblocks.config.tenant = ->(_request) { 'acme' }
      block = add_block(@form, 'email')

      post "/forms/#{@form.id}/pages"
      assert_response :not_found
      patch "#{blocks_path}/#{block.id}", headers: turbo_headers, params: { block: { label: 'Hijack' } }
      assert_response :not_found
      assert_equal 'Email', block.reload.label
    end
  end
end
