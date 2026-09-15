# frozen_string_literal: true

require 'csv'

module Formblocks
  # A form's responses as CSV: one column per input block (labelled), plus a
  # column for any key a since-deleted block left behind, so nothing that
  # was collected is lost.
  class CsvExport
    # Cells starting with these would be evaluated as formulas by
    # spreadsheets; a leading apostrophe makes them text.
    FORMULA_LEADERS = ['=', '+', '-', '@', "\t", "\r"].freeze

    attr_reader :form, :responses

    def initialize(form, responses = nil)
      @form = form
      @responses = (responses || form.responses.newest_first).to_a
    end

    def filename
      "#{form.slug}-responses-#{Date.current.iso8601}.csv"
    end

    def generate
      blocks = form.input_blocks
      known = blocks.map(&:key)
      orphans = responses.flat_map { |r| r.answers.to_h.keys }.uniq - known

      CSV.generate do |csv|
        csv << [I18n.t('formblocks.responses.csv.submitted_at'), *blocks.map do |b|
          b.label.presence || b.key
        end, *orphans]
        responses.each do |response|
          cells = blocks.map { |b| b.display_answer(response.answer(b)) } +
                  orphans.map { |key| response.answers.to_h[key].to_s }
          csv << [response.created_at.iso8601, *cells.map { |cell| self.class.safe(cell) }]
        end
      end
    end

    def self.safe(value)
      value = value.to_s
      FORMULA_LEADERS.any? { |leader| value.start_with?(leader) } ? "'#{value}" : value
    end
  end
end
