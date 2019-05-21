# frozen_string_literal: true

# Decorates QingGroups for rendering outside ODK. There is a separate QingGroup decorator for ODK.
class QingGroupDecorator < FormItemDecorator
  # Unique, sorted list of questionings this group refers to via display conditions
  def refd_qings
    @refd_qings ||= super.uniq.sort_by(&:full_rank)
  end

  def group_link
    h.read_only ? h.qing_group_path(object) : h.edit_qing_group_path(object)
  end

  def modal_title
    I18n.t("activerecord.attributes.qing_group.#{h.action_name}", name: group_name)
  end
end
