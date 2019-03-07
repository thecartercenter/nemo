# frozen_string_literal: true

class UserGroupDecorator < ApplicationDecorator
  delegate_all

  # UserGroups don't have edit or show pages.
  def default_path
    nil
  end
end
