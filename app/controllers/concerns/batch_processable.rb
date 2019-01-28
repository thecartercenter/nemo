module BatchProcessable
  extend ActiveSupport::Concern

  # Restricts the given scope to the specific objects checked by the user, if any.
  # If no boxes checked, or if the select_all_pages option is set, returns the scope unchanged.
  def restrict_scope_to_selected_objects(rel)
    return rel if params[:select_all_pages] == "1" || params[:selected].nil?
    rel.where(id: params[:selected].keys)
    end
end
