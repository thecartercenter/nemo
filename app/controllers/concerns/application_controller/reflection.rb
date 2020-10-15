# frozen_string_literal: true

module ApplicationController::Reflection
  extend ActiveSupport::Concern

  # attempts to get the model class controlled by this controller
  # not always appropriate
  # Should be overridden by children controllers with unguessable names.
  def model_class
    @model_class ||= controller_name.classify.constantize
  end
end
