# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def assign_attributes(*)
    super
  rescue ArgumentError
    raise if valid?
  end
end
