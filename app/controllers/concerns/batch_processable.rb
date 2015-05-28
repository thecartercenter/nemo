module BatchProcessable
  extend ActiveSupport::Concern

  def load_selected_objects(klass)
    klass = klass.accessible_by(current_ability)
    if params[:select_all]
      klass.all.to_a
    elsif params[:selected]
      params[:selected].keys.collect{ |id| klass.find_by_id(id) }.compact
    else
      []
    end
  end
end
