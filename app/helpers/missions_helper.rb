module MissionsHelper
  def missions_index_links(missions)
    can?(:create, Mission) ? [create_link(Mission)] : []
  end
  
  def missions_index_fields
    %w(name created_at actions)
  end
  
  def format_missions_field(mission, field)
    case field
    when "name" then link_to(mission.name, mission_path(mission), :title => t("common.view"))
    when "created_at" then l(mission.created_at)
    when "actions" then action_links(mission, :exclude => :show, :obj_name => mission.name)
    else mission.send(field)
    end
  end
end
