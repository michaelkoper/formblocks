# frozen_string_literal: true

module Formblocks
  # One submission of a form. `answers` is a hash keyed by block key
  # ("email" => "ada@example.com"); validation runs every input block's rules
  # against it, so the public page can show an error under each field.
  class Response < ApplicationRecord
    belongs_to :form, inverse_of: :responses, counter_cache: true

    attribute :answers, default: -> { {} }

    before_validation { self.tenant = form&.tenant }
    validate :validate_answers

    after_create_commit :notify_host

    scope :for_tenant, ->(tenant) { where(tenant: tenant.presence&.to_s) }
    scope :newest_first, -> { order(created_at: :desc, id: :desc) }

    # Takes the submitted values (a hash keyed by block key) and keeps only the
    # form's own inputs, each normalized by its block.
    def fill(submitted)
      submitted = submitted.to_h.stringify_keys
      self.answers = form.input_blocks.to_h do |block|
        [block.key, block.normalize_answer(submitted[block.key])]
      end
      self
    end

    def answer(block)
      answers.to_h[block.key]
    end

    def error_for(block)
      errors[block.key].first
    end

    private

    def validate_answers
      form.input_blocks.each { |block| block.validate_answer(answer(block), errors) }
    end

    def notify_host
      Formblocks.config.on_submit.call(self)
    end
  end
end
