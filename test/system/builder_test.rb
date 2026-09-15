# frozen_string_literal: true

require 'application_system_test_case'

# The builder's JavaScript: the palette, autosave, the in-place button text and
# the publish flow, driven in a real browser.
module Formblocks
  class BuilderTest < ApplicationSystemTestCase
    setup { as_admin! }

    test 'adding a block from the palette and autosaving its label' do
      form = create_form
      visit "/forms/#{form.id}/edit"
      assert_text 'Page 1'

      within('.fb-page-card', match: :first) do
        find('summary', text: 'Add block').click
        click_button 'Email'
      end

      within('.fb-page-card', match: :first) do
        assert_selector '.fb-block', count: 1
        assert_field 'block[label]', with: 'Email'
        fill_in 'block[label]', with: 'Work email'
        fill_in 'block[placeholder]', with: 'you@company.com'
        check 'block[required]'
        assert_selector '.fb-autosave-status', text: 'Saved'
      end

      block = form.reload.steps.first.blocks.first
      assert_equal 'Work email', block.label
      assert_equal 'you@company.com', block.placeholder
      assert_predicate block, :required?
      assert_equal 'email', block.key
    end

    test 'the page button text is edited in place' do
      form = create_form
      visit "/forms/#{form.id}/edit"

      assert_field 'page[button_text]', with: 'Submit'
      fill_in 'page[button_text]', with: 'Send it'
      assert_selector '.fb-page-card__footer .fb-autosave-status', text: 'Saved'

      assert_equal 'Send it', form.steps.first.reload.button_text
      refresh
      assert_field 'page[button_text]', with: 'Send it'
    end

    test 'a block is removed after confirming' do
      form = create_form
      add_block(form, 'email')
      visit "/forms/#{form.id}/edit"

      within('.fb-page-card', match: :first) do
        accept_confirm { find('.fb-iconbtn--danger').click }
        assert_no_selector '.fb-block'
      end
      assert_empty form.steps.first.blocks.reload
    end

    test 'publishing shows the public URL and the form goes live' do
      form = create_form(template: 'contact')
      visit "/forms/#{form.id}/edit"

      click_button 'Publish'

      assert_text 'Your form is live'
      assert_match %r{\Ahttp://(127\.0\.0\.1|localhost):\d+/f/contact-form\z}, find('#fb-public-url').value
      assert_predicate form.reload, :published?

      visit '/f/contact-form'
      assert_selector 'form.fb-form'
      assert_field 'Your name'
    end
  end
end
