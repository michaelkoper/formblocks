# frozen_string_literal: true

require 'application_system_test_case'

# The visitor's side: one step at a time, browser validation before moving on,
# and the submission landing on the thank-you page.
module Formblocks
  class PublicFormSystemTest < ApplicationSystemTestCase
    test 'a two-step form validates each step and submits at the end' do
      create_form(template: 'lead', publish: true)
      visit '/f/lead-capture'

      assert_text 'Step 1 of 2'
      assert_text 'Request a demo'
      assert_no_text 'A bit about your team'

      click_button 'Continue' # required fields are empty: the browser refuses
      assert_no_text 'A bit about your team'

      fill_in 'Full name', with: 'Ada Lovelace'
      fill_in 'Work email', with: 'ada@example.com'
      click_button 'Continue'

      assert_text 'Step 2 of 2'
      assert_text 'A bit about your team'
      assert_no_text 'Request a demo'

      click_button 'Back'
      assert_text 'Step 1 of 2'
      assert_field 'Full name', with: 'Ada Lovelace'
      click_button 'Continue'

      choose '2–10'
      fill_in 'What are you hoping to solve?', with: 'Faster onboarding'
      click_button 'Request demo'

      assert_text 'Thank you!'
      response = Response.last
      assert_equal 'Ada Lovelace', response.answers['full_name']
      assert_equal '2–10', response.answers['team_size']
      assert_equal 'Faster onboarding', response.answers['what_are_you_hoping_to_solve']
    end

    test 'a server-side error opens the step it belongs to' do
      form = create_form(template: 'lead', publish: true)
      form.input_blocks.first.update!(required: false)
      visit '/f/lead-capture?preview=0'

      fill_in 'Work email', with: 'ada@example.com'
      click_button 'Continue'
      assert_text 'Step 2 of 2'
      choose '2–10'
      # Bypass the browser's own check with a value the server rejects.
      page.execute_script("document.querySelector('[name=\"answers[work_email]\"]').type = 'text'")
      page.execute_script("document.querySelector('[name=\"answers[work_email]\"]').value = 'not-an-email'")
      click_button 'Request demo'

      assert_text 'Please check the highlighted fields.'
      assert_text 'Step 1 of 2'
      assert_text 'Work email is not a valid email address'
      assert_equal 0, Response.count
    end
  end
end
