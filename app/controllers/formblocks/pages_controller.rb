# frozen_string_literal: true

module Formblocks
  class PagesController < DashboardController
    before_action :set_form
    before_action :set_page, only: %i[update destroy move]

    def create
      page = @form.pages.create!(kind: 'step')
      @form.resequence_pages!
      redirect_to builder_path(dom_id(page)), status: :see_other
    end

    # The page's button text, autosaved from the builder.
    def update
      if @page.update(page_params)
        turbo_request? ? head(:no_content) : redirect_to(builder_path(dom_id(@page)), status: :see_other)
      else
        head :unprocessable_content
      end
    end

    def destroy
      @page.destroy! if @page.step? && @form.steps.size > 1
      @form.resequence_pages!
      redirect_to builder_path, status: :see_other
    end

    def move
      @page.move(params[:direction])
      redirect_to builder_path(dom_id(@page)), status: :see_other
    end

    private

    def set_page
      @page = @form.pages.find(params.expect(:id))
    end

    def page_params
      params.expect(page: [:button_text])
    end
  end
end
