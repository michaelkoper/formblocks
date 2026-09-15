# frozen_string_literal: true

module Formblocks
  # Form templates offered on the "New form" page. A template is a plain hash:
  #
  #   {
  #     title: 'Contact form',
  #     description: 'Name, email and a message.',
  #     pages: [
  #       { button_text: 'Send',
  #         blocks: [
  #           { type: 'heading', content: 'Get in touch' },
  #           { type: 'email', label: 'Email', required: true }
  #         ] }
  #     ],
  #     thank_you: { blocks: [{ type: 'heading', content: 'Thanks!' }] }
  #   }
  #
  # `type` is a block kind (see Formblocks::Block.kinds); the other keys are
  # block attributes. Hosts add their own with
  # `Formblocks.config.templates['webinar'] = { ... }` and remove a built-in
  # with `Formblocks.config.templates.delete('contact')`.
  module Templates
    def self.builtin
      {
        'contact' => {
          title: 'Contact form',
          description: 'Name, email and a message. The classic.',
          pages: [
            { button_text: 'Send message',
              blocks: [
                { type: 'heading', content: 'Get in touch' },
                { type: 'paragraph', content: 'Leave us a message and we will get back to you within a day.' },
                { type: 'name', label: 'Your name', required: true },
                { type: 'email', label: 'Email address', required: true },
                { type: 'textarea', label: 'Message', required: true, placeholder: 'How can we help?' }
              ] }
          ],
          thank_you: {
            blocks: [
              { type: 'heading', content: 'Thanks for reaching out!' },
              { type: 'paragraph', content: 'We have received your message and will reply soon.' }
            ]
          }
        },
        'lead' => {
          title: 'Lead capture',
          description: 'Two steps: contact details first, then a few qualifying questions.',
          pages: [
            { button_text: 'Continue',
              blocks: [
                { type: 'heading', content: 'Request a demo' },
                { type: 'name', label: 'Full name', required: true },
                { type: 'email', label: 'Work email', required: true },
                { type: 'phone', label: 'Phone number' },
                { type: 'url', label: 'Company website' }
              ] },
            { button_text: 'Request demo',
              blocks: [
                { type: 'heading', content: 'A bit about your team' },
                { type: 'radio_group', label: 'Team size', required: true,
                  options: ['Just me', '2–10', '11–50', '51+'] },
                { type: 'textarea', label: 'What are you hoping to solve?' },
                { type: 'checkbox', label: 'Send me product updates by email' }
              ] }
          ],
          thank_you: {
            blocks: [
              { type: 'heading', content: 'Thank you!' },
              { type: 'paragraph', content: 'We will be in touch shortly to schedule your demo.' }
            ]
          }
        },
        'feedback' => {
          title: 'Feedback survey',
          description: 'A quick rating and an open comment.',
          pages: [
            { button_text: 'Send feedback',
              blocks: [
                { type: 'heading', content: 'How are we doing?' },
                { type: 'radio_group', label: 'How satisfied are you?', required: true,
                  options: ['Very satisfied', 'Satisfied', 'Neutral', 'Unsatisfied', 'Very unsatisfied'] },
                { type: 'textarea', label: 'What could we do better?' },
                { type: 'email', label: 'Email, if you would like a reply' }
              ] }
          ],
          thank_you: {
            blocks: [
              { type: 'heading', content: 'Thanks for your feedback!' },
              { type: 'paragraph', content: 'Every answer helps us improve.' }
            ]
          }
        }
      }
    end
  end
end
