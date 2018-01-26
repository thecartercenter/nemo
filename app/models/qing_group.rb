class QingGroup < FormItem
  include Translatable

  translates :group_name, :group_hint, :group_item_name

  alias_method :c, :sorted_children

  def code
    group_name
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

  def normalize
    super
    self.group_item_name_translations = {} unless repeatable?
    true
  end
end
