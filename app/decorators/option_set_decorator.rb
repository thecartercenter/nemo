# frozen_string_literal: true

class OptionSetDecorator < ApplicationDecorator
  delegate_all

  # Returns the edit path if the user has edit abilities, else the show path.
  def default_path
    @default_path ||= h.can?(:update, object) ? h.edit_option_set_path(object) : h.option_set_path(object)
  end
end
