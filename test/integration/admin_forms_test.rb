# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class AdminFormsTest < ActionDispatch::IntegrationTest
    setup { as_admin! }

    test 'the admin is forbidden by default outside development' do
      reset_formblocks_config!

      get '/forms'

      assert_response :forbidden
      assert_match 'authorize_admin', response.body
    end

    test 'index lists only the tenant’s forms, with status and response count' do
      Formblocks.config.tenant = ->(request) { request.headers['X-Tenant'] }
      mine = create_form(title: 'Mine', tenant: 'acme', publish: true)
      create_form(title: 'Theirs', tenant: 'other')

      get '/forms', headers: { 'X-Tenant' => 'acme' }

      assert_response :success
      assert_select 'a[href=?]', "/forms/#{mine.id}/edit", text: 'Mine'
      assert_select 'a', text: 'Theirs', count: 0
      assert_select '.fb-badge--published', text: 'Published'
      assert_select 'a[href=?]', "/forms/#{mine.id}/responses", text: '0'
      assert_select 'link[rel=stylesheet][href^="/forms/assets/admin.css?v="]'
      assert_select 'script[type=module][src^="/forms/assets/admin.js?v="]'
    end

    test 'index shows an empty state' do
      get '/forms'

      assert_response :success
      assert_select '.fb-empty', text: /No forms yet/
    end

    test 'new offers a blank form and every template' do
      get '/forms/new'

      assert_response :success
      assert_select 'button', text: 'Start blank'
      assert_select 'button', text: 'Use template', count: 3
      assert_select 'input[name=template][value=lead]'
    end

    test 'create makes a blank form and opens the builder' do
      assert_difference -> { Form.count }, 1 do
        post '/forms'
      end
      form = Form.last

      assert_redirected_to "/forms/#{form.id}/edit"
      assert_equal 'Untitled form', form.title
      assert_equal %w[step thank_you], form.pages.map(&:kind)
      follow_redirect!
      assert_select '.fb-flash--notice', text: 'Form created.'
    end

    test 'create builds a form from a template and assigns the tenant' do
      Formblocks.config.tenant = ->(_request) { 'acme' }

      post '/forms', params: { template: 'contact' }
      form = Form.last

      assert_redirected_to "/forms/#{form.id}/edit"
      assert_equal 'Contact form', form.title
      assert_equal 'acme', form.tenant
      assert_equal 5, form.steps.first.blocks.size
    end

    test 'create falls back to a blank form for an unknown template' do
      post '/forms', params: { template: 'nope' }

      assert_equal 'Untitled form', Form.last.title
    end

    test 'the builder shows every page, its blocks, the palette and the publish bar' do
      form = create_form(template: 'lead')

      get "/forms/#{form.id}/edit"

      assert_response :success
      assert_select 'title', text: 'Lead capture · Forms · Dummy'
      assert_select '.fb-page-card', count: 3
      assert_select '.fb-block', count: form.blocks.count
      assert_select 'h2', text: 'Page 1'
      assert_select 'h2', text: 'Thank you page'
      block = form.steps.first.blocks.first
      assert_select 'form[action=?][data-controller=fb-autosave]',
                    "/forms/#{form.id}/pages/#{block.page_id}/blocks/#{block.id}"
      assert_select 'input[name="page[button_text]"][value=Continue]'
      assert_select '.fb-builder > .fb-page-card:last-child .fb-palette__item', text: 'Email', count: 0
      assert_select '.fb-builder > .fb-page-card:last-child .fb-palette__item', text: 'Heading', count: 1
      assert_select '.fb-builder > .fb-page-card:first-child .fb-palette__item', count: Block.kinds.size
      assert_select 'form[action=?] button', "/forms/#{form.id}/publish", text: 'Publish'
      assert_select 'a[href=?][target=_blank]', 'http://www.example.com/f/lead-capture?preview=1', text: /Preview/
      assert_select 'style', text: /--fb-primary: #111827/
      assert_select 'meta[name=turbo-refresh-method][content=morph]'
    end

    test 'the builder shows the public URL and Unpublish once published' do
      form = create_form(publish: true)

      get "/forms/#{form.id}/edit"

      assert_select 'a[href=?]', 'http://www.example.com/f/contact'
      assert_select 'form[action=?] button', "/forms/#{form.id}/unpublish", text: 'Unpublish'
      assert_select 'button', text: 'Publish', count: 0
    end

    test 'settings shows the form and saves title, slug and colors' do
      form = create_form

      get "/forms/#{form.id}/settings"
      assert_response :success
      assert_select 'input[name="form[title]"][value=Contact]'
      assert_select '.fb-input-group__prefix', text: 'http://www.example.com/f/'

      patch "/forms/#{form.id}",
            params: { form: { title: 'Say hello', slug: 'hello', primary_color: '#FF0000', button_text_color: '' } }

      assert_redirected_to "/forms/#{form.id}/settings"
      form.reload
      assert_equal 'Say hello', form.title
      assert_equal 'hello', form.slug
      assert_equal '#ff0000', form.primary_color
      assert_nil form.button_text_color
    end

    test 'settings rejects an invalid slug' do
      form = create_form

      patch "/forms/#{form.id}", params: { form: { slug: 'Bad Slug' } }

      assert_response :unprocessable_entity
      assert_select '.fb-errors li', text: /Slug/
      assert_equal 'contact', form.reload.slug
    end

    test 'settings uploads, rejects and removes a logo' do
      form = create_form

      patch "/forms/#{form.id}", params: { form: { logo: png_upload } }
      assert_redirected_to "/forms/#{form.id}/settings"
      assert_predicate form.reload.logo, :attached?

      get "/forms/#{form.id}/settings"
      assert_select '.fb-logo-preview img'
      assert_select 'input[name="form[remove_logo]"]'

      patch "/forms/#{form.id}", params: { form: { logo: text_upload } }
      assert_response :unprocessable_entity
      assert_select '.fb-errors li', text: /Logo must be an image/

      patch "/forms/#{form.id}", params: { form: { remove_logo: '1' } }
      assert_not form.reload.logo.attached?
    end

    test 'destroy deletes the form and everything under it' do
      form = create_form(template: 'contact')

      assert_difference -> { Form.count } => -1, -> { Block.count } => -form.blocks.count do
        delete "/forms/#{form.id}"
      end
      assert_redirected_to '/forms/'
    end

    test 'duplicate opens the builder of the copy' do
      form = create_form(template: 'contact', publish: true)

      assert_difference -> { Form.count }, 1 do
        post "/forms/#{form.id}/duplicate"
      end
      copy = Form.last

      assert_redirected_to "/forms/#{copy.id}/edit"
      assert_equal 'Contact form (copy)', copy.title
      assert_not copy.published?
      assert_equal form.blocks.count, copy.blocks.count
    end

    test 'publish leads to the published page with the public URL' do
      form = create_form

      post "/forms/#{form.id}/publish"

      assert_redirected_to "/forms/#{form.id}/published"
      assert_predicate form.reload, :published?
      follow_redirect!
      assert_select 'h1', text: 'Your form is live'
      assert_select 'input#fb-public-url[value=?]', 'http://www.example.com/f/contact'
      assert_select 'a[href=?][target=_blank]', 'http://www.example.com/f/contact'
      assert_select 'a[href=?]', "/forms/#{form.id}/responses"
      assert_select 'a[href=?]', "/forms/#{form.id}/edit"
    end

    test 'unpublish returns to the builder' do
      form = create_form(publish: true)

      post "/forms/#{form.id}/unpublish"

      assert_redirected_to "/forms/#{form.id}/edit"
      assert_not form.reload.published?
    end

    test 'a form of another tenant is not found' do
      Formblocks.config.tenant = ->(_request) { 'acme' }
      form = create_form(tenant: 'other')

      get "/forms/#{form.id}/edit"
      assert_response :not_found

      patch "/forms/#{form.id}", params: { form: { title: 'Hijack' } }
      assert_response :not_found
      assert_equal 'Contact', form.reload.title
    end

    test 'every admin page is gated' do
      form = create_form
      reset_formblocks_config!

      [['/forms', :get], ['/forms/new', :get], ['/forms', :post], ["/forms/#{form.id}/edit", :get],
       ["/forms/#{form.id}/settings", :get], ["/forms/#{form.id}", :patch], ["/forms/#{form.id}", :delete],
       ["/forms/#{form.id}/publish", :post], ["/forms/#{form.id}/published", :get],
       ["/forms/#{form.id}/responses", :get], ['/forms/settings', :get]].each do |path, verb|
        public_send(verb, path)
        assert_response :forbidden, "#{verb.upcase} #{path} should be forbidden"
      end
      assert_not form.reload.published?
    end
  end
end
