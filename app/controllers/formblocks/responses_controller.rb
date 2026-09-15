# frozen_string_literal: true

module Formblocks
  class ResponsesController < DashboardController
    PER_PAGE = 50

    before_action :set_form
    before_action :set_response, only: %i[show destroy]

    def index
      respond_to do |format|
        format.html do
          @page = [params[:page].to_i, 1].max
          @responses = @form.responses.newest_first.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
          @more = @responses.size > PER_PAGE
          @responses = @responses.first(PER_PAGE)
          @columns = @form.input_blocks.select(&:visible?).first(3)
        end
        format.csv do
          export = CsvExport.new(@form)
          send_data export.generate, filename: export.filename, type: 'text/csv'
        end
      end
    end

    def show; end

    def destroy
      @response.destroy!
      redirect_to form_responses_path(@form), notice: t('formblocks.flash.response_deleted'), status: :see_other
    end

    private

    def set_response
      @response = @form.responses.find(params.expect(:id))
    end
  end
end
