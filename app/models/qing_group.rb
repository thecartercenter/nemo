class QingGroup < FormItem
  include Translatable

  translates :group_name

  replicable child_assocs: :children, backward_assocs: :form, dont_copy: [:form_id]

  alias_method :c, :children

  # tests if all questions in the group have the same type and option set
  def grid_mode?(qings)
    qings.all?{ |q| q.qtype.name == 'select_one' && q.option_set == qings[0].option_set }
  end
end
