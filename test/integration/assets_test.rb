# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class AssetsTest < ActionDispatch::IntegrationTest
    test 'every asset is served same-origin with its content type' do
      types = { 'admin.css' => 'text/css', 'admin.js' => 'text/javascript', 'public.css' => 'text/css',
                'public.js' => 'text/javascript', 'turbo.js' => 'text/javascript', 'stimulus.js' => 'text/javascript' }
      types.each do |name, type|
        get "/forms/assets/#{name}"

        assert_response :success, name
        assert_equal type, response.media_type, name
      end
    end

    test 'an unknown asset is not found' do
      get '/forms/assets/nope.js'

      assert_response :not_found
    end

    test 'the fingerprinted URL is cached for a year; any other URL only revalidates' do
      fingerprint = Assets.fingerprint('admin.css')

      get "/forms/assets/admin.css?v=#{fingerprint}"
      assert_match(/max-age=315\d{5}/, response.headers['Cache-Control'])
      assert_match 'public', response.headers['Cache-Control']

      get '/forms/assets/admin.css?v=stale'
      assert_no_match(/max-age=315\d{5}/, response.headers['Cache-Control'])
      assert_predicate response.headers['ETag'], :present?
    end

    test 'a matching ETag answers 304' do
      get '/forms/assets/admin.js'
      etag = response.headers['ETag']

      get '/forms/assets/admin.js', headers: { 'If-None-Match' => etag }

      assert_response :not_modified
    end

    test 'the modules import Turbo and Stimulus by fingerprinted URL' do
      get '/forms/assets/admin.js'

      assert_match %{import(new URL("turbo.js?v=#{Assets.fingerprint('turbo.js')}", base))}, response.body
      assert_match %{import(new URL("stimulus.js?v=#{Assets.fingerprint('stimulus.js')}", base))}, response.body
      assert_no_match '{{', response.body
      assert_match 'if (!window.Turbo)', response.body

      get '/forms/assets/public.js'
      assert_match %(stimulus.js?v=#{Assets.fingerprint('stimulus.js')}), response.body
      assert_no_match 'turbo.js', response.body
    end

    test 'Turbo and Stimulus come from their gems' do
      get '/forms/assets/turbo.js'
      assert_match(/Turbo \d+\.\d+/, response.body)

      get '/forms/assets/stimulus.js'
      assert_match 'Stimulus', response.body
    end

    test 'assets need no admin and no CSRF token' do
      reset_formblocks_config!

      get '/forms/assets/admin.css'

      assert_response :success
    end
  end
end
