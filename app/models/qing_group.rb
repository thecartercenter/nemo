class QingGroup < FormItem
  include Translatable

  translates :group_name, :group_hint

  alias_method :c, :sorted_children

  def code
    nil
  end

  def qtype_name
    nil
  end

  def child_groups
    children.where(type: "QingGroup")
  end

  def group?
    true
  end

  def option_set_id
    nil
  end

  def preordered_option_nodes
    []
  end
end
