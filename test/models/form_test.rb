# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class FormTest < ActiveSupport::TestCase
    test 'a new form gets one empty step and a thank-you page with default content' do
      form = create_form

      assert_equal %w[step thank_you], form.pages.map(&:kind)
      assert_equal [1, 2], form.pages.map(&:position)
      assert_empty form.steps.first.blocks
      assert_equal %w[heading paragraph], form.thank_you_page.blocks.map(&:kind)
      assert_equal 'Thank you!', form.thank_you_page.blocks.first.content
    end

    test 'the slug comes from the title and takes a suffix when taken' do
      assert_equal 'contact-us', create_form(title: 'Contact us').slug
      assert_equal 'contact-us-2', create_form(title: 'Contact us').slug
      assert_equal 'contact-us-3', create_form(title: 'Contact Us!').slug
    end

    test 'a slug the user types is validated rather than rewritten' do
      create_form(title: 'Taken')
      form = create_form(title: 'Other')

      form.slug = 'taken'
      assert_not form.valid?
      assert_predicate form.errors[:slug], :any?

      form.slug = 'Has Spaces'
      assert_not form.valid?

      form.slug = ' Fine-Slug-2 '
      assert_predicate form, :valid?
      assert_equal 'fine-slug-2', form.slug
    end

    test 'blanking the slug regenerates it from the title' do
      form = create_form(title: 'Contact')
      form.update!(title: 'Say hello', slug: '')

      assert_equal 'say-hello', form.slug
    end

    test 'publishing keeps the first published_at and unpublishing clears it' do
      form = create_form
      assert_not form.published?
      assert_equal 'draft', form.status

      form.publish!
      first = form.reload.published_at
      assert_predicate form, :published?
      assert_equal 'published', form.status

      travel 1.hour do
        form.publish!
      end
      assert_equal first, form.reload.published_at

      form.unpublish!
      assert_nil form.published_at
    end

    test 'colors fall back to the settings, then to the configured defaults' do
      form = create_form
      assert_equal '#111827', form.effective_primary_color
      assert_equal '#ffffff', form.effective_button_text_color

      Setting.for_tenant(nil).update!(primary_color: '#ABCDEF', button_text_color: '#000')
      form = Form.find(form.id)
      assert_equal '#abcdef', form.effective_primary_color
      assert_equal '#000', form.effective_button_text_color

      form.update!(primary_color: '#123456')
      assert_equal '#123456', form.effective_primary_color
      assert_equal '#000', form.effective_button_text_color
    end

    test 'settings are per tenant' do
      Setting.for_tenant('acme').update!(primary_color: '#ff0000')

      assert_equal '#ff0000', create_form(tenant: 'acme').effective_primary_color
      assert_equal '#111827', create_form(title: 'B', tenant: 'other').effective_primary_color
    end

    test 'colors must be hex' do
      form = create_form

      form.primary_color = 'red'
      assert_not form.valid?
      form.primary_color = '#12345G'
      assert_not form.valid?
      form.primary_color = ' #FFF '
      assert_predicate form, :valid?
      assert_equal '#fff', form.primary_color
      form.primary_color = ''
      assert_predicate form, :valid?
      assert_nil form.primary_color
    end

    test 'from_template builds the pages, blocks and unique keys' do
      form = Form.from_template(Templates.builtin['lead'])
      assert_predicate form, :new_record?
      form.save!

      assert_equal 'Lead capture', form.title
      assert_equal 2, form.steps.size
      assert_equal 'Continue', form.steps.first.button_text
      assert_equal %w[full_name work_email phone_number company_website team_size what_are_you_hoping_to_solve
                      send_me_product_updates_by_email], form.input_blocks.map(&:key)
      assert_equal ['Just me', '2–10', '11–50', '51+'], form.input_blocks[4].options
      assert_equal 'Thank you!', form.thank_you_page.blocks.first.content
      assert_equal [1, 2, 3], form.pages.map(&:position)
    end

    test 'from_template accepts string keys and de-duplicates keys' do
      definition = { 'title' => 'Two texts',
                     'pages' => [{ 'blocks' => [{ 'type' => 'text', 'label' => 'Answer' },
                                                { 'type' => 'text', 'label' => 'Answer' }] }] }
      form = Form.from_template(definition, tenant: 'acme', title: 'Custom')
      form.save!

      assert_equal 'Custom', form.title
      assert_equal 'acme', form.tenant
      assert_equal %w[answer answer_2], form.input_blocks.map(&:key)
      assert form.thank_you_page
      assert_empty form.thank_you_page.blocks
    end

    test 'from_template raises on an unknown block kind' do
      assert_raises(ArgumentError) { Form.from_template(pages: [{ blocks: [{ type: 'nope' }] }]) }
    end

    test 'duplicate deep-copies pages and blocks into a fresh draft without responses' do
      form = create_form(template: 'lead', publish: true)
      response = form.responses.new
      response.fill('full_name' => 'Ada', 'work_email' => 'ada@example.com', 'team_size' => '2–10')
      response.save!

      copy = form.duplicate

      assert_predicate copy, :persisted?
      assert_equal 'Lead capture (copy)', copy.title
      assert_equal 'lead-capture-copy', copy.slug
      assert_not copy.published?
      assert_equal 0, copy.responses_count
      assert_empty copy.responses
      assert_equal(form.pages.map { |p| [p.kind, p.position, p.button_text] },
                   copy.pages.map { |p| [p.kind, p.position, p.button_text] })
      assert_equal(form.input_blocks.map { |b| [b.kind, b.key, b.label, b.required?, b.options] },
                   copy.input_blocks.map { |b| [b.kind, b.key, b.label, b.required?, b.options] })
      assert_empty form.blocks.ids & copy.blocks.ids
      assert_equal 1, form.reload.responses_count
    end

    test 'duplicate copies the logo as a new blob' do
      form = create_form
      form.logo.attach(io: StringIO.new(PNG), filename: 'logo.png', content_type: 'image/png')

      copy = form.duplicate

      assert_predicate copy.logo, :attached?
      assert_not_equal form.logo.blob.id, copy.logo.blob.id
      assert_equal PNG, copy.logo.download
    end

    test 'the logo must be an image within the size limit' do
      form = create_form
      form.logo.attach(io: StringIO.new('hello'), filename: 'notes.txt', content_type: 'text/plain')
      assert_not form.valid?
      assert_equal ['must be an image'], form.errors[:logo]

      Formblocks.config.max_upload_size = 10
      other = create_form(title: 'Other')
      other.logo.attach(io: StringIO.new(PNG), filename: 'logo.png', content_type: 'image/png')
      assert_not other.valid?
      assert_match 'too large', other.errors[:logo].first
    end

    test 'remove_logo purges the logo on save' do
      form = create_form
      form.logo.attach(io: StringIO.new(PNG), filename: 'logo.png', content_type: 'image/png')
      assert_predicate form.reload.logo, :attached?

      form.update!(remove_logo: true)

      assert_not form.reload.logo.attached?
    end

    test 'effective_logo is the form logo, else the settings logo, else nil' do
      form = create_form
      assert_nil form.effective_logo

      setting = Setting.for_tenant(nil)
      setting.logo.attach(io: StringIO.new(PNG), filename: 'global.png', content_type: 'image/png')
      setting.save!
      form = Form.find(form.id)
      assert_equal 'global.png', form.effective_logo.filename.to_s

      form.logo.attach(io: StringIO.new(PNG), filename: 'own.png', content_type: 'image/png')
      assert_equal 'own.png', form.effective_logo.filename.to_s
    end

    test 'resequence_pages! keeps the thank-you page last' do
      form = create_form
      page = form.pages.create!(kind: 'step')
      assert_equal 3, page.position

      form.resequence_pages!

      assert_equal %w[step step thank_you], form.pages.map(&:kind)
      assert_equal [1, 2, 3], form.pages.map(&:position)
    end

    test 'for_tenant scopes forms; blank means the global collection' do
      a = create_form(tenant: 'a')
      create_form(title: 'B', tenant: 'b')
      global = create_form(title: 'G')

      assert_equal [a], Form.for_tenant('a').to_a
      assert_equal [global], Form.for_tenant(nil).to_a
      assert_equal [global], Form.for_tenant('').to_a
    end

    test 'input_blocks lists step inputs in page order and skips the thank-you page' do
      form = create_form(template: 'lead')

      assert_equal 7, form.input_blocks.size
      assert form.input_blocks.all?(&:input?)
      assert_equal %w[full_name work_email phone_number company_website], form.input_blocks.first(4).map(&:key)
    end

    test 'destroying a form removes its pages, blocks and responses' do
      form = create_form(template: 'contact')
      response = form.responses.new
      response.fill('your_name' => 'Ada', 'email_address' => 'ada@example.com', 'message' => 'Hi')
      response.save!

      form.destroy!

      assert_equal 0, Page.count
      assert_equal 0, Block.count
      assert_equal 0, Response.count
    end
  end
end
