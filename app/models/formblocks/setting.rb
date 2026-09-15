# frozen_string_literal: true

module Formblocks
  # Per-tenant brand defaults: colors and a logo every form inherits unless
  # it sets its own. One row per tenant, created on first save.
  class Setting < ApplicationRecord
    include Attachable

    attachable :logo

    normalizes :primary_color, :button_text_color, with: ->(color) { color.to_s.strip.downcase.presence }

    validates :primary_color, :button_text_color, format: { with: Form::COLOR_FORMAT }, allow_nil: true

    def self.for_tenant(tenant)
      find_or_initialize_by(tenant: tenant.presence&.to_s)
    end
  end
end
