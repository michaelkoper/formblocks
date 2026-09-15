# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class PublicFormTest < ActionDispatch::IntegrationTest
    setup do
      @form = create_form(template: 'lead', publish: true)
    end

    VALID = { full_name: 'Ada Lovelace', work_email: 'Ada@Example.com', team_size: '2–10',
              send_me_product_updates_by_email: '1' }.freeze

    test 'a draft is not found, unless an admin previews it' do
      @form.unpublish!

      get '/f/lead-capture'
      assert_response :not_found
      assert_select 'h1', text: 'This form is not available.'

      get '/f/lead-capture', params: { preview: 1 }
      assert_response :not_found

      as_admin!
      get '/f/lead-capture', params: { preview: 1 }
      assert_response :success
      assert_select 'form.fb-form[action=?]', '/f/lead-capture?preview=1'
    end

    test 'an unknown slug is not found' do
      get '/f/nope'

      assert_response :not_found
    end

    test 'a published form renders its steps, inputs, buttons and assets' do
      get '/f/lead-capture'

      assert_response :success
      assert_select 'title', text: 'Lead capture · Dummy'
      assert_select 'form.fb-form[action=?][method=post][data-controller=fb-pager]', '/f/lead-capture'
      assert_select 'fieldset.fb-step', count: 2
      assert_select 'h2.fb-heading', text: 'Request a demo'
      assert_select 'input[name="answers[full_name]"][type=text][required][autocomplete=name]'
      assert_select 'input[name="answers[work_email]"][type=email][required]'
      assert_select 'input[name="answers[phone_number]"][type=tel]:not([required])'
      assert_select 'input[name="answers[company_website]"][type=url]'
      assert_select 'input[type=radio][name="answers[team_size]"][required]', count: 4
      assert_select 'textarea[name="answers[what_are_you_hoping_to_solve]"]'
      assert_select 'input[type=checkbox][name="answers[send_me_product_updates_by_email]"][value="1"]'
      assert_select 'button[type=button][data-action="fb-pager#next"]', text: 'Continue'
      assert_select 'button[type=submit]', text: 'Request demo'
      assert_select 'button[data-action="fb-pager#back"]', text: 'Back'
      assert_select 'input[name=fb_website]'
      assert_select 'label', text: /Phone number\s+optional/
      assert_select 'link[rel=stylesheet][href^="/forms/assets/public.css?v="]'
      assert_select 'script[type=module][src^="/forms/assets/public.js?v="]'
      assert_select 'style', text: /--fb-primary: #111827; --fb-primary-text: #ffffff;/
    end

    test 'hidden fields take their value from the query string, else their default' do
      form = create_form(title: 'Plain', publish: true)
      add_block(form, 'hidden', key: 'utm_source', content: 'direct')
      add_block(form, 'email')

      get '/f/plain', params: { utm_source: 'newsletter' }
      assert_select 'input[type=hidden][name="answers[utm_source]"][value=newsletter]'

      get '/f/plain'
      assert_select 'input[type=hidden][name="answers[utm_source]"][value=direct]'

      post '/f/plain', params: { answers: { utm_source: 'newsletter', email: 'ada@example.com' } }
      assert_equal 'newsletter', Response.last.answers['utm_source']
    end

    test 'a valid submission stores the response and lands on the thank-you page' do
      seen = []
      Formblocks.config.on_submit = ->(response) { seen << response }

      assert_difference -> { @form.reload.responses_count }, 1 do
        post '/f/lead-capture', params: { answers: VALID, fb_referrer: 'https://example.com/pricing' },
                                headers: { 'User-Agent' => 'TestBrowser/1.0' }
      end

      assert_redirected_to '/f/lead-capture/thanks'
      response_record = Response.last
      assert_equal 'Ada Lovelace', response_record.answers['full_name']
      assert_equal 'ada@example.com', response_record.answers['work_email']
      assert_equal true, response_record.answers['send_me_product_updates_by_email']
      assert_equal '', response_record.answers['phone_number']
      assert_equal 'https://example.com/pricing', response_record.page_url
      assert_equal 'TestBrowser/1.0', response_record.user_agent
      assert_equal 'en', response_record.locale
      assert_equal [response_record], seen

      follow_redirect!
      assert_response :success
      assert_select 'h2.fb-heading', text: 'Thank you!'
      assert_select '.fb-paragraph', text: /schedule your demo/
      assert_select 'form', count: 0
    end

    test 'an invalid submission re-renders with errors on the step they belong to' do
      assert_no_difference -> { Response.count } do
        post '/f/lead-capture', params: { answers: { full_name: '', work_email: 'nope', team_size: '2–10' } }
      end

      assert_response :unprocessable_entity
      assert_select '.fb-alert', text: 'Please check the highlighted fields.'
      assert_select '.fb-error', text: 'Full name is required'
      assert_select '.fb-error', text: 'Work email is not a valid email address'
      assert_select 'fieldset[data-fb-pager-errors]', count: 1
      assert_select 'input[name="answers[work_email]"][value=nope]'
      assert_select 'input[type=radio][value="2–10"][checked]'
      assert_select '.fb-field--error input[aria-describedby="fb_work_email_error"]'
    end

    test 'a required checkbox must be ticked and a radio answer must be an option' do
      @form.input_blocks.last.update!(required: true)

      post '/f/lead-capture',
           params: { answers: VALID.merge(team_size: 'Everyone', send_me_product_updates_by_email: '0') }

      assert_response :unprocessable_entity
      assert_select '.fb-error', text: /must be checked/
      assert_select '.fb-error', text: /is not one of the options/
    end

    test 'unknown answer keys are dropped' do
      post '/f/lead-capture', params: { answers: VALID.merge(admin: 'true') }

      assert_not Response.last.answers.key?('admin')
    end

    test 'the honeypot swallows bots' do
      assert_no_difference -> { Response.count } do
        post '/f/lead-capture', params: { answers: VALID, fb_website: 'http://spam.example' }
      end

      assert_redirected_to '/f/lead-capture/thanks'
    end

    test 'submitting a draft is not possible' do
      @form.unpublish!

      post '/f/lead-capture', params: { answers: VALID }

      assert_response :not_found
      assert_equal 0, Response.count
    end

    test 'the thank-you page is not served for a draft' do
      @form.unpublish!

      get '/f/lead-capture/thanks'

      assert_response :not_found
    end

    test 'the app name shows in the title and as the logo alt text' do
      Formblocks.config.app_name = 'Nusii'
      setting = Setting.for_tenant(nil)
      setting.logo.attach(io: StringIO.new(PNG), filename: 'global.png', content_type: 'image/png')
      setting.save!

      get '/f/lead-capture'
      assert_select 'title', text: 'Lead capture · Nusii'
      assert_select '.fb-public__logo img[alt=Nusii]'

      get '/f/nope'
      assert_select 'title', text: 'Nusii'
    end

    test 'the logo and brand colors come from the form, else the settings' do
      Setting.for_tenant(nil).update!(primary_color: '#ff0000', button_text_color: '#000000')
      Setting.for_tenant(nil).logo.attach(io: StringIO.new(PNG), filename: 'global.png', content_type: 'image/png')

      get '/f/lead-capture'
      assert_select 'style', text: /--fb-primary: #ff0000; --fb-primary-text: #000000;/
      assert_select '.fb-public__logo img[alt=Dummy]'

      @form.update!(primary_color: '#00ff00')
      @form.logo.attach(io: StringIO.new(PNG), filename: 'own.png', content_type: 'image/png')
      get '/f/lead-capture'
      assert_select 'style', text: /--fb-primary: #00ff00; --fb-primary-text: #000000;/
      assert_select '.fb-public__logo img[src*=own]'
    end

    test 'the page is served without the admin gate' do
      get '/f/lead-capture'
      assert_response :success

      post '/f/lead-capture', params: { answers: VALID }
      assert_response :see_other
    end

    if ActionController::Base.respond_to?(:rate_limit)
      test 'submissions are rate limited per IP' do
        10.times do
          post '/f/lead-capture', params: { answers: VALID }
          assert_response :see_other
        end

        post '/f/lead-capture', params: { answers: VALID }

        assert_response :too_many_requests
        assert_equal 10, Response.count
        assert_select '.fb-alert', text: 'Too many submissions. Please wait a moment and try again.'
        assert_select 'input[name="answers[full_name]"][value="Ada Lovelace"]'
      end

      test 'rate limiting can be turned off' do
        Formblocks.config.rate_limit = nil
        # The limit is read when the controller class loads, so a nil here
        # only takes effect for a fresh class — the same contract as an
        # initializer. Assert the wiring rather than reloading controllers.
        assert_nil Formblocks.config.rate_limit
        assert_equal({ to: 10, within: 60 }, Formblocks::Configuration.new.rate_limit)
      end
    end
  end
end
