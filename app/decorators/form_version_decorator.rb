# frozen_string_literal: true

class FormVersionDecorator < ApplicationDecorator
  delegate_all

  # Version name for displaying to user
  def name
    "#{number}-#{code}"
  end
end
