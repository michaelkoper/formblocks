# frozen_string_literal: true

require 'test_helper'

# The dummy app runs a strict nonce-based CSP (see its
# content_security_policy initializer). Every page the engine renders has to
# carry the nonce where it matters, and nothing else may need an exception.
module Formblocks
  class CspTest < ActionDispatch::IntegrationTest
    test 'the admin pages carry the nonce on the meta tag, the module script and the brand style' do
      as_admin!
      form = create_form

      get "/forms/#{form.id}/edit"

      assert_response :success
      assert_select 'meta[name=csp-nonce][content=testnonce]'
      assert_select 'script[type=module][nonce=testnonce][src^="/forms/assets/admin.js"]'
      assert_select 'style[nonce=testnonce]', text: /--fb-primary/
      assert_select '[style]', count: 0
      assert_select '[onclick], [onchange], [oninput]', count: 0
      assert_match(/script-src 'self' 'nonce-testnonce'/, response.headers['Content-Security-Policy'])
    end

    test 'the public page carries the nonce and no inline styles either' do
      form = create_form(template: 'lead', publish: true)
      form.update!(primary_color: '#ff0000')

      get '/f/lead-capture'

      assert_response :success
      assert_select 'meta[name=csp-nonce][content=testnonce]'
      assert_select 'script[type=module][nonce=testnonce][src^="/forms/assets/public.js"]'
      assert_select 'style[nonce=testnonce]', text: /--fb-primary: #ff0000/
      assert_select '[style]', count: 0
      assert_match(/style-src 'self' 'nonce-testnonce'/, response.headers['Content-Security-Policy'])
    end

    test 'the thank-you and the not-found pages render under the policy too' do
      create_form(template: 'contact', publish: true)

      get '/f/contact-form/thanks'
      assert_response :success
      assert_select 'style[nonce=testnonce]'

      get '/f/nope'
      assert_response :not_found
      assert_select 'meta[name=csp-nonce][content=testnonce]'
    end
  end
end
