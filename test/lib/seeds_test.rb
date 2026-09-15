# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class SeedsTest < ActiveSupport::TestCase
    test 'creates three template forms, two published with responses, and is idempotent' do
      result = Seeds.load!

      assert_equal %w[demo-contact demo-lead-capture demo-feedback], result[:forms].map(&:slug)
      assert_equal %w[published published draft], result[:forms].map(&:status)
      assert_equal 5, result[:responses].size
      assert_equal 2, Form.find_by!(slug: 'demo-contact').reload.responses_count
      assert_equal 3, Form.find_by!(slug: 'demo-lead-capture').reload.responses_count
      assert_equal 'ada@example.com', Response.first.answers['email_address']
      assert result[:responses].all?(&:persisted?)

      Seeds.load!

      assert_equal 3, Form.count
      assert_equal 5, Response.count
    end

    test 'seeds a tenant' do
      result = Seeds.load!(tenant: 'acme')

      assert(result[:forms].all? { |form| form.tenant == 'acme' })
      assert(result[:responses].all? { |response| response.tenant == 'acme' })
    end
  end
end
