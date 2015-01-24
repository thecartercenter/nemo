class QingGroup < FormItem
  include Translatable

  translates :group_name

  replicable child_assocs: :children, backward_assocs: :form, dont_copy: [:form_id]

  alias_method :c, :children

end
