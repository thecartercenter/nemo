# frozen_string_literal: true

class FormDecorator < ApplicationDecorator
  delegate_all

  # Returns the edit path if the user has edit abilities, else the show path.
  def default_path
    @default_path ||= h.can?(:update, object) ? h.edit_form_path(object) : h.form_path(object)
  end

  def status_with_icon
    h.content_tag(:div, class: "form-status status-#{form.status}") do
      circle = (draft? ? +"" : h.icon_tag("circle", class: "status-circle") << nbsp)
      circle << t("form.statuses.#{form.status}")
    end
  end

  def current_version_name
    current_version&.decorate&.name
  end

  # Option tags for the minimum version dropdown.
  def minimum_version_options
    possible_versions = versions.decorate.reverse
    h.options_from_collection_for_select(possible_versions, :id, :name, minimum_version_id)
  end
end
