# frozen_string_literal: true

# Base class for all AR models
class ApplicationRecord < ActiveRecord::Base
  acts_as_copy_target

  self.abstract_class = true

  # dsl-style method for setting clone options
  def self.clone_options(**options)
    if options.empty?
      return {} unless class_variable_defined?("@@clone_options")
      return class_variable_get("@@clone_options")
    end
    class_variable_set("@@clone_options", options)
  end
end
