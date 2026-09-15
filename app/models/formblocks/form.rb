# frozen_string_literal: true

module Formblocks
  # A form: a title, a slug for its public URL, brand colors, a logo, and its
  # pages. Every form has at least one step page and exactly one thank-you
  # page, which is always last.
  class Form < ApplicationRecord
    include Attachable

    COLOR_FORMAT = /\A#(?:[0-9a-f]{3}){1,2}\z/i
    SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    has_many :pages, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :form
    has_many :blocks, through: :pages
    has_many :responses, dependent: :destroy, inverse_of: :form
    attachable :logo

    normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase.presence }
    normalizes :primary_color, :button_text_color, with: ->(color) { color.to_s.strip.downcase.presence }

    before_validation :assign_slug
    after_create :ensure_pages

    validates :title, presence: true, length: { maximum: 200 }
    validates :slug, presence: true, length: { maximum: 100 }, uniqueness: true,
                     format: { with: SLUG_FORMAT }
    validates :primary_color, :button_text_color, format: { with: COLOR_FORMAT }, allow_nil: true

    scope :for_tenant, ->(tenant) { where(tenant: tenant.presence&.to_s) }
    scope :newest_first, -> { order(updated_at: :desc, id: :desc) }
    scope :published, -> { where.not(published_at: nil) }

    def published?
      published_at.present?
    end

    def status
      published? ? 'published' : 'draft'
    end

    def publish!
      update!(published_at: published_at || Time.current)
    end

    def unpublish!
      update!(published_at: nil)
    end

    # The pages a visitor fills in, in order. The thank-you page is separate.
    def steps
      pages.select(&:step?)
    end

    def thank_you_page
      pages.find(&:thank_you?)
    end

    # Every input a visitor can answer, in page order. Answers and CSV columns
    # follow this order.
    def input_blocks
      steps.flat_map(&:blocks).select(&:input?)
    end

    # The tenant's global settings — the fallback for colors and logo.
    def settings
      @settings ||= Setting.for_tenant(tenant)
    end

    def effective_primary_color
      primary_color.presence || settings.primary_color.presence || Formblocks.config.default_primary_color
    end

    def effective_button_text_color
      button_text_color.presence || settings.button_text_color.presence ||
        Formblocks.config.default_button_text_color
    end

    # The form's own logo, else the global one, else nil.
    def effective_logo
      return unless Formblocks.attachments?
      return logo if logo.attached?

      settings.logo if settings.logo.attached?
    end

    # Puts the thank-you page last and numbers the pages 1..n. Called after
    # anything that adds, removes or moves a page.
    def resequence_pages!
      steps, rest = pages.reload.partition(&:step?)
      (steps + rest).each_with_index do |page, index|
        page.update_column(:position, index + 1) unless page.position == index + 1
      end
      pages.reset
    end

    # A deep copy — pages, blocks, logo and images — as a new draft with a
    # fresh slug. Responses are not copied.
    def duplicate
      copy = dup
      copy.assign_attributes(title: "#{title} (copy)", slug: nil, published_at: nil, responses_count: 0)
      attachments = [[self, copy, :logo]]

      pages.each do |page|
        page_copy = page.dup
        copy.pages << page_copy
        page.blocks.each do |block|
          block_copy = block.dup
          page_copy.blocks << block_copy
          attachments << [block, block_copy, :image]
        end
      end

      transaction do
        copy.save!
        attachments.each { |from, to, name| self.class.copy_attachment(from, to, name) }
      end
      copy
    end

    class << self
      # Builds (does not save) a form from a template definition — see
      # Formblocks::Templates for the shape.
      def from_template(definition, tenant: nil, title: nil)
        definition = definition.to_h.deep_symbolize_keys
        form = new(title: title.presence || definition[:title], tenant:)
        keys = []

        Array(definition[:pages]).each_with_index do |page_def, index|
          page = form.pages.build(kind: 'step', position: index + 1, button_text: page_def[:button_text])
          build_blocks(page, page_def[:blocks], keys)
        end

        thank_you = form.pages.build(kind: 'thank_you', position: form.pages.size + 1)
        build_blocks(thank_you, definition.dig(:thank_you, :blocks), keys)
        form
      end

      # Attachments are copied blob-for-blob rather than shared: purging a
      # shared blob from one record would take it away from the other.
      def copy_attachment(from, to, name)
        return unless Formblocks.attachments?

        source = from.public_send(name)
        return unless source.attached?

        blob = source.blob
        to.public_send(name).attach(io: StringIO.new(blob.download), filename: blob.filename.to_s,
                                    content_type: blob.content_type)
      end

      private

      def build_blocks(page, definitions, keys)
        Array(definitions).each_with_index do |attrs, index|
          attrs = attrs.to_h.symbolize_keys
          klass = Block.find_kind(attrs.delete(:type))
          block = page.blocks.build(attrs.merge(type: klass.name, position: index + 1))
          next unless block.input?

          block.key = Block.unique_key(block.key.presence || block.default_key, keys)
          keys << block.key
        end
      end
    end

    private

    # From the title on first save, or whenever the slug was blanked in the
    # settings. A taken slug gets a numeric suffix; a slug the user typed
    # themselves is validated instead, so they see why it was refused.
    def assign_slug
      return if slug.present?

      base = title.to_s.parameterize.presence || 'form'
      base = base.first(90)
      candidate = base
      n = 2
      while self.class.where.not(id: id).exists?(slug: candidate)
        candidate = "#{base}-#{n}"
        n += 1
      end
      self.slug = candidate
    end

    def ensure_pages
      pages.create!(kind: 'step') if pages.none?(&:step?)
      if pages.none?(&:thank_you?)
        thank_you = pages.create!(kind: 'thank_you')
        thank_you.blocks.create!(type: 'Formblocks::Blocks::Heading',
                                 content: I18n.t('formblocks.public.thanks_title'))
        thank_you.blocks.create!(type: 'Formblocks::Blocks::Paragraph',
                                 content: I18n.t('formblocks.public.thanks_message'))
      end
      resequence_pages!
    end
  end
end
