# frozen_string_literal: true

require 'test_helper'

module Formblocks
  class UrlBlockTest < ActiveSupport::TestCase
    test 'image_answer? recognises links to pictures' do
      block = Blocks::Url.new

      assert block.image_answer?('https://cdn.example.com/ada.jpg')
      assert block.image_answer?('https://cdn.example.com/ada.PNG?w=200')
      assert block.image_answer?('https://res.cloudinary.com/demo/image/upload/v1/Forms/Testimonials/1422a129')
      assert_not block.image_answer?('https://example.com/profile')
      assert_not block.image_answer?('https://example.com/report.pdf')
      assert_not block.image_answer?('ftp://example.com/ada.jpg')
      assert_not block.image_answer?(nil)
    end
  end
end
