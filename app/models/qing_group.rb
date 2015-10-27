class QingGroup < FormItem
  include Translatable

  translates :group_name, :group_hint

  replicable child_assocs: :children, backward_assocs: :form, dont_copy: [:form_id]

  alias_method :c, :children

  scope(:child_groups, ->(children) { children.where(type: "QingGroup").all })

end
