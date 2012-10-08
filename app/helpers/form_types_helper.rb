module FormTypesHelper
  def form_types_index_links(form_types)
    [link_to_if_auth("Add new Form Type", new_form_type_path, "form_types#create")]
  end
  def form_types_index_fields
    %w[name actions]
  end
  def format_form_types_field(form_type, field)
    case field
    when "actions"
      action_links(form_type, :destroy_warning => "Are you sure you want to delete Form Type '#{form_type.name}'?")
    else form_type.send(field)
    end
  end
end
