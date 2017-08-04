class QingGroup < FormItem
  include Translatable

  translates :group_name, :group_hint

  replicable child_assocs: :children, backward_assocs: :form, dont_copy: [:form_id]

  alias_method :c, :sorted_children

  def child_groups
    children.where(type: "QingGroup")
  end

  def odk_code
    @odk_code ||= "grp#{id}"
  end

  def option_set_id
    nil
  end

  def preordered_option_nodes
    []
  end

  def fragment?
    false # is QingGroup, so isn't a fragment
  end

  def multilevel_fragment?
    false # is QingGroup, so isn't a fragment
  end

  def multilevel_children?
    children.any?(&:multilevel?)
  end
end
