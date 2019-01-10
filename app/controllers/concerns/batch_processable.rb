module BatchProcessable
  extend ActiveSupport::Concern

  def load_selected_objects(klass, rel)
    return rel if params[:select_all].present?

    if params[:selected].present?
      ids = params[:selected].keys
      rel.where(id: ids)
    else
      rel
    end
  end
end
