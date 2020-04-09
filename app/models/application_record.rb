# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # dsl-style method for setting clone options
  def self.clone_options(**options)
    return class_variable_get("@@clone_options") if options.empty?
    class_variable_set("@@clone_options", options)
  end
end
