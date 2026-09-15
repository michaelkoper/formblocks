# frozen_string_literal: true

module Formblocks
  # Demo data for trying the gem out: three forms built from the built-in
  # templates — two published, with a few responses each, and one draft.
  # Idempotent: running it again refreshes the same forms (found by slug)
  # instead of duplicating them.
  module Seeds
    SLUGS = { 'contact' => 'demo-contact', 'lead' => 'demo-lead-capture', 'feedback' => 'demo-feedback' }.freeze

    RESPONSES = {
      'demo-contact' => [
        { 'your_name' => 'Ada Lovelace', 'email_address' => 'ada@example.com',
          'message' => 'Could you send over the enterprise pricing?' },
        { 'your_name' => 'Grace Hopper', 'email_address' => 'grace@example.com',
          'message' => "Loved the demo.\nWhen does the API ship?" }
      ],
      'demo-lead-capture' => [
        { 'full_name' => 'Linus Torvalds', 'work_email' => 'linus@example.com', 'team_size' => 'Just me',
          'send_me_product_updates_by_email' => '1' },
        { 'full_name' => 'Margaret Hamilton', 'work_email' => 'margaret@example.com',
          'phone_number' => '+1 617 555 0100', 'company_website' => 'https://apollo.example', 'team_size' => '51+',
          'what_are_you_hoping_to_solve' => 'Onboarding for a distributed team.' },
        { 'full_name' => 'Ken Thompson', 'work_email' => 'ken@example.com', 'team_size' => '2–10' }
      ]
    }.freeze

    def self.load!(tenant: nil)
      forms = SLUGS.to_h do |template, slug|
        definition = Templates.builtin.fetch(template)
        form = Form.find_by(slug:) || Form.from_template(definition, tenant:).tap { |f| f.slug = slug }
        form.tenant = tenant
        form.save!
        template == 'feedback' ? form.unpublish! : form.publish!
        [slug, form]
      end

      responses = RESPONSES.flat_map do |slug, answers_list|
        form = forms.fetch(slug)
        form.responses.destroy_all
        answers_list.map do |answers|
          form.responses.new(page_url: 'https://example.com/pricing', locale: 'en',
                             user_agent: 'Mozilla/5.0 (demo)').fill(answers).tap(&:save!)
        end
      end

      { forms: forms.values, responses: }
    end
  end
end
