# frozen_string_literal: true

# Decorates QingGroups for rendering outside ODK. There is a separate QingGroup decorator for ODK.
class QingGroupDecorator < ApplicationDecorator
  delegate_all

  # Unique, sorted list of questionings to which this group refers to via display conditions
  def refd_qings
    qing_group.display_conditions.map(&:ref_qing).uniq.sort_by(&:full_rank)
  end
end
