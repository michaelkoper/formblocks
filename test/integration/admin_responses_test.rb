# frozen_string_literal: true

require 'test_helper'
require 'csv'

module Formblocks
  class AdminResponsesTest < ActionDispatch::IntegrationTest
    setup do
      as_admin!
      @form = create_form(template: 'contact', publish: true)
    end

    def submit(name: 'Ada', email: 'ada@example.com', message: 'Hello')
      response = @form.responses.new(page_url: 'https://example.com/pricing', user_agent: 'TestBrowser/1.0',
                                     locale: 'en')
      response.fill('your_name' => name, 'email_address' => email, 'message' => message)
      response.save!
      response
    end

    test 'index shows an empty state and no CSV link' do
      get "/forms/#{@form.id}/responses"

      assert_response :success
      assert_select '.fb-empty', text: /No responses yet/
      assert_select 'a', text: /Download CSV/, count: 0
    end

    test 'index lists responses with the first three inputs as columns' do
      first = submit
      second = submit(name: 'Bob', email: 'bob@example.com', message: 'Hi')

      get "/forms/#{@form.id}/responses"

      assert_response :success
      assert_select 'h2', text: '2 responses'
      assert_select 'th', text: 'Your name'
      assert_select 'th', text: 'Email address'
      assert_select 'th', text: 'Message'
      assert_select 'tbody tr', count: 2
      assert_select 'tbody tr:first-child td', text: 'Bob'
      assert_select 'a[href=?]', "/forms/#{@form.id}/responses/#{first.id}"
      assert_select 'a[href=?]', "/forms/#{@form.id}/responses/#{second.id}"
      assert_select 'a[href=?][data-turbo=false]', "/forms/#{@form.id}/responses.csv", text: /Download CSV/
      assert_select '.fb-tab.is-active', text: /Responses/
    end

    test 'index paginates after fifty' do
      51.times { submit }

      get "/forms/#{@form.id}/responses"
      assert_select 'tbody tr', count: 50
      assert_select 'a[href=?]', "/forms/#{@form.id}/responses?page=2", text: 'Load more'

      get "/forms/#{@form.id}/responses", params: { page: 2 }
      assert_select 'tbody tr', count: 1
      assert_select 'a', text: 'Load more', count: 0
    end

    test 'the CSV downloads every response' do
      submit
      submit(name: 'Bob', email: 'bob@example.com', message: 'Hi')

      get "/forms/#{@form.id}/responses.csv"

      assert_response :success
      assert_equal 'text/csv', response.media_type
      assert_match(/attachment; filename="contact-form-responses-\d{4}-\d{2}-\d{2}\.csv"/,
                   response.headers['Content-Disposition'])
      rows = CSV.parse(response.body)
      assert_equal ['Submitted at', 'Your name', 'Email address', 'Message'], rows.first
      assert_equal 3, rows.size
      assert_equal 'Bob', rows[1][1]
    end

    test 'show renders every answer and the metadata' do
      response = submit(message: "Line one\nLine two")

      get "/forms/#{@form.id}/responses/#{response.id}"

      assert_response :success
      assert_select 'dt', text: 'Your name'
      assert_select 'dd', text: 'Ada'
      assert_select 'dd.fb-pre', text: /Line one\s+Line two/
      assert_select 'dd', text: 'https://example.com/pricing'
      assert_select 'dd', text: 'TestBrowser/1.0'
      assert_select 'form[action=?] button', "/forms/#{@form.id}/responses/#{response.id}", text: 'Delete'
    end

    test 'destroy deletes the response and updates the count' do
      response = submit

      assert_difference -> { @form.reload.responses_count }, -1 do
        delete "/forms/#{@form.id}/responses/#{response.id}"
      end
      assert_redirected_to "/forms/#{@form.id}/responses"
    end

    test 'responses of another tenant’s form are not reachable' do
      response = submit
      Formblocks.config.tenant = ->(_request) { 'acme' }

      get "/forms/#{@form.id}/responses"
      assert_response :not_found
      get "/forms/#{@form.id}/responses.csv"
      assert_response :not_found
      delete "/forms/#{@form.id}/responses/#{response.id}"
      assert_response :not_found
      assert Response.exists?(response.id)
    end
  end
end
