module MissionsHelper
  def missions_index_links(missions)
    can?(:create, Mission) ? [create_link(Mission)] : []
  end

  def missions_index_fields
    %w(name compact_name locked created_at)
  end

  def format_missions_field(mission, field)
    case field
    when "name" then link_to(mission.name, mission_path(mission), :title => t("common.view"))
    when "locked" then tbool(mission.locked?)
    when "created_at" then l(mission.created_at)
    else mission.send(field)
    end
  end
end
