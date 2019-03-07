# frozen_string_literal: true

class MissionDecorator < ApplicationDecorator
  delegate_all

  # Returns the edit path if the user has edit abilities, else the show path.
  def default_path
    @default_path ||= h.can?(:update, object) ? h.edit_mission_path(object) : h.mission_path(object)
  end
end
