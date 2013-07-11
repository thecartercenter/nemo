module FormTypesHelper
  def form_types_index_links(form_types)
    can?(:create, FormType) ? [create_link(FormType)] : []
  end
  
  def form_types_index_fields
    %w(name actions)
  end
  
  def format_form_types_field(form_type, field)
    case field
    when "name" then link_to(form_type.name, form_type_path(form_type), :title => t("common.view"))
    when "actions" then action_links(form_type, :obj_name => form_type.name)
    else form_type.send(field)
    end
  end
end
