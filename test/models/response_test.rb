# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class ResponseTest < ActiveSupport::TestCase
    setup do
      @form = create_form(template: 'lead')
    end

    test 'answers default to an empty hash' do
      assert_equal({}, Response.new.answers)
    end

    test "fill keeps only the form's inputs and normalizes each answer" do
      response = @form.responses.new.fill('full_name' => ' Ada ', 'work_email' => 'ADA@Example.com',
                                          'send_me_product_updates_by_email' => '1', 'bogus' => 'x')

      assert_equal 'Ada', response.answers['full_name']
      assert_equal 'ada@example.com', response.answers['work_email']
      assert_equal true, response.answers['send_me_product_updates_by_email']
      assert_equal '', response.answers['phone_number']
      assert_not response.answers.key?('bogus')
    end

    test 'validation follows every input block and keys errors by block key' do
      response = @form.responses.new.fill('work_email' => 'nope')

      assert_not response.valid?
      assert_equal ['is required'], response.errors[:full_name]
      assert_equal ['is not a valid email address'], response.errors[:work_email]
      assert_equal ['is required'], response.errors[:team_size]
      assert_empty response.errors[:phone_number]
      assert_equal 'is required', response.error_for(@form.input_blocks.first)
    end

    test 'saving counts on the form and copies its tenant' do
      form = create_form(template: 'contact', tenant: 'acme')
      response = form.responses.new.fill('your_name' => 'Ada', 'email_address' => 'ada@example.com', 'message' => 'Hi')

      assert_difference -> { form.reload.responses_count }, 1 do
        response.save!
      end
      assert_equal 'acme', response.tenant
      assert_equal [response], Response.for_tenant('acme').to_a
    end

    test 'on_submit receives the saved response' do
      seen = []
      Formblocks.config.on_submit = ->(response) { seen << response }

      response = @form.responses.new.fill('full_name' => 'Ada', 'work_email' => 'ada@example.com',
                                          'team_size' => '2–10')
      response.save!

      assert_equal [response], seen
      assert_predicate seen.first, :persisted?
    end

    test 'on_submit is not called for an invalid response' do
      seen = []
      Formblocks.config.on_submit = ->(response) { seen << response }

      assert_not @form.responses.new.fill({}).save
      assert_empty seen
    end

    test 'answers survive a round trip through the database as strings and booleans' do
      response = @form.responses.new.fill('full_name' => 'Ada', 'work_email' => 'ada@example.com',
                                          'team_size' => '2–10', 'send_me_product_updates_by_email' => '1')
      response.save!

      stored = Response.find(response.id)
      assert_equal 'Ada', stored.answers['full_name']
      assert_equal true, stored.answers['send_me_product_updates_by_email']
      assert_equal '2–10', stored.answer(@form.input_blocks[4])
    end
  end
end
