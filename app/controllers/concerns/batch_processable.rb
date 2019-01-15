module BatchProcessable
  extend ActiveSupport::Concern

  def load_selected_objects(rel)
    return rel if params[:select_all].present? || params[:selected].nil?
    rel.where(id: params[:selected].keys)
    end
end
