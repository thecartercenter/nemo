# frozen_string_literal: true

class FormDecorator < ApplicationDecorator
  delegate_all

  # Returns the edit path if the user has edit abilities, else the show path.
  def default_path
    @default_path ||= h.can?(:update, object) ? h.edit_form_path(object) : h.form_path(object)
  end
end
