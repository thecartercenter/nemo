module MissionsHelper
  def missions_index_links(missions)
    [link_to_if_auth("Add new Mission", new_mission_path, "missions#create")]
  end
  def missions_index_fields
    %w[name created actions]
  end
  def format_missions_field(mission, field)
    case field
    when "created"
      mission.created_at.to_s(:std_date)
    when "actions"
      action_links(mission, :exclude => [:show], :destroy_warning => "Are you sure you want to delete Mission '#{mission.name}'?")
    else mission.send(field)
    end
  end
end
