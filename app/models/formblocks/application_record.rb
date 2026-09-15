# frozen_string_literal: true

module Formblocks
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
