module BatchProcessable
  extend ActiveSupport::Concern

  def load_selected_objects(klass)
    params[:selected].keys.collect{|id| klass.find_by_id(id)}.compact
  end
end
