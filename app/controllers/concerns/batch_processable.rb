module BatchProcessable
  extend ActiveSupport::Concern

  def load_selected_objects(klass)
    # inline with the controller action, take a scope instead and add to it
    klass = klass.accessible_by(current_ability)
    if params[:select_all].present?
      klass.all.to_a
      # where id: 
    elsif params[:selected].present?
      params[:selected].keys.collect{ |id| klass.find_by_id(id) }.compact
    else
      []
    end
  end
end
