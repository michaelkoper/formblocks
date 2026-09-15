# frozen_string_literal: true

require 'test_helper'
require 'csv'

module Formblocks
  class CsvExportTest < ActiveSupport::TestCase
    setup do
      @form = create_form(template: 'contact')
    end

    def submit(name, email, message)
      response = @form.responses.new.fill('your_name' => name, 'email_address' => email, 'message' => message)
      response.save!
      response
    end

    test 'one row per response, newest first, with the block labels as headers' do
      first = submit('Ada', 'ada@example.com', "Hello\nthere")
      second = submit('Bob', 'bob@example.com', 'Hi')

      rows = CSV.parse(CsvExport.new(@form).generate)

      assert_equal ['Submitted at', 'Your name', 'Email address', 'Message'], rows[0]
      assert_equal [second.created_at.iso8601, 'Bob', 'bob@example.com', 'Hi'], rows[1]
      assert_equal [first.created_at.iso8601, 'Ada', 'ada@example.com', "Hello\nthere"], rows[2]
      assert_equal 3, rows.size
    end

    test 'answers of a since-deleted block get their own column' do
      submit('Ada', 'ada@example.com', 'Hi')
      @form.input_blocks.last.destroy!

      rows = CSV.parse(CsvExport.new(@form.reload).generate)

      assert_equal ['Submitted at', 'Your name', 'Email address', 'message'], rows[0]
      assert_equal 'Hi', rows[1][3]
    end

    test 'cells that spreadsheets would run as formulas are neutralised' do
      submit('=SUM(A1:A9)', 'ada@example.com', '+1 -2 @x')

      row = CSV.parse(CsvExport.new(@form).generate)[1]

      assert_equal "'=SUM(A1:A9)", row[1]
      assert_equal "'+1 -2 @x", row[3]
      assert_equal 'ada@example.com', row[2]
    end

    test 'checkbox answers read Yes or No and the filename carries the slug and date' do
      form = create_form(template: 'lead')
      response = form.responses.new.fill('full_name' => 'Ada', 'work_email' => 'ada@example.com', 'team_size' => '2–10',
                                         'send_me_product_updates_by_email' => '1')
      response.save!

      export = CsvExport.new(form)

      assert_equal 'Yes', CSV.parse(export.generate)[1].last
      assert_equal "lead-capture-responses-#{Date.current.iso8601}.csv", export.filename
    end
  end
end
