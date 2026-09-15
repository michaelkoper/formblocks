# frozen_string_literal: true

module Formblocks
  class BlocksController < DashboardController
    before_action :set_form, :set_page
    before_action :set_block, only: %i[update destroy move]

    # Adds a block of `params[:kind]` from the palette, with its defaults.
    def create
      klass = Block.find_kind(params[:kind])
      return head :unprocessable_content unless @page.allowed_block_classes.include?(klass)

      block = @page.blocks.create!(klass.default_attributes.merge(type: klass.name))
      redirect_to builder_path(dom_id(block)), status: :see_other
    rescue ArgumentError
      head :bad_request
    end

    # Autosaved from the builder. A text edit answers 204 so the field keeps
    # focus; an upload re-renders the card so the new image shows.
    def update
      if @block.update(block_params)
        if !turbo_request?
          redirect_to builder_path(dom_id(@block)), status: :see_other
        elsif rerender_after_update?
          render turbo_stream: replace_block
        else
          head :no_content
        end
      elsif turbo_request?
        render turbo_stream: replace_block, status: :unprocessable_content
      else
        redirect_to builder_path(dom_id(@block)), alert: @block.errors.full_messages.to_sentence, status: :see_other
      end
    end

    def destroy
      @block.destroy!
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@block)) }
        format.html { redirect_to builder_path(dom_id(@page)), status: :see_other }
      end
    end

    def move
      @block.move(params[:direction])
      redirect_to builder_path(dom_id(@block)), status: :see_other
    end

    # Drag-and-drop order for the whole page: `ids` in their new order.
    def reorder
      @page.reorder_blocks(params[:ids])
      head :no_content
    end

    private

    def set_page
      @page = @form.pages.find(params.expect(:page_id))
    end

    def set_block
      @block = @page.blocks.find(params.expect(:id))
    end

    def block_params
      permitted = %i[label placeholder help_text content required options_text key]
      permitted += %i[image remove_image] if Formblocks.attachments?
      params.expect(block: [*permitted])
    end

    def rerender_after_update?
      Formblocks.attachments? && @block.image? &&
        (params.dig(:block, :image).present? || params.dig(:block, :remove_image).present?)
    end

    def replace_block
      turbo_stream.replace(dom_id(@block), partial: 'formblocks/blocks/block', locals: { block: @block })
    end
  end
end
