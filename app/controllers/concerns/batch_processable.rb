module BatchProcessable
  extend ActiveSupport::Concern

  # Restricts the given scope to the specific objects checked by the user, if any.
  # If no boxes checked, or if the select_all_pages option is set, returns the scope unchanged.
  def restrict_scope_to_selected_objects(rel)
    return rel if params[:select_all_pages] == "1" || params[:selected].nil?
    rel.where(id: params[:selected].keys)
  end

  def restrict_by_search_and_ability_and_selection(scope, klass, search_options: {})
    # We only check accessible_by index permission because that is what the user would have seen in the index
    # view where they initiate an action.
    # Downstream users of this method's output should check additional permissions if appropriate.
    scope = scope.accessible_by(current_ability, :index)
    scope = apply_search_if_given(klass, scope, **search_options)
    restrict_scope_to_selected_objects(scope)
  end
end
