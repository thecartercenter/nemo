# frozen_string_literal: true

class MakeTagUniqueByNameAndMission < ActiveRecord::Migration[5.1]
  def up
    # returns PG::Result like [{"agg_array": "{tag_id, tag_id}", "name": "tag_id", "mission_id": m_id}]
    # GROUP_BY treats null as equal, so works for standard tags that have mission_id = null
    select_sql =
      "SELECT array_agg(id), name, mission_id FROM tags GROUP BY name, mission_id HAVING count(*) > 1"
    duplicate_tag_data = execute(select_sql)
    duplicate_tag_data.each do |duplicate_data|
      tag_ids = duplicate_data["array_agg"][1...-1].split(",")
      tag_to_keep_id = tag_ids.slice!(0)
      tag_ids_to_replace = tag_ids.map { |id| "'#{id}'" }.join(",")
      update_sql = "UPDATE taggings SET tag_id = '#{tag_to_keep_id}' WHERE tag_id IN (#{tag_ids_to_replace})"
      execute(update_sql)
      delete_sql = "DELETE FROM tags WHERE tags.id IN (#{tag_ids_to_replace})"
      execute(delete_sql)
    end
    remove_index(:tags, column: %i[name mission_id])
    add_index(:tags, %i[name mission_id],
      unique: true,
      name: "index_tags_on_name_and_mission_id",
      where: "deleted_at IS NULL")
    add_index(:tags, :name,
      unique: true,
      name: "index_tags_on_name_where_mission_id_null",
      where: "deleted_at IS NULL AND mission_id IS NULL")
  end

  def down
    remove_index(:tags, name: "index_tags_on_name_and_mission_id")
    remove_index(:tags, name: "index_tags_on_name_where_mission_id_null")
    add_index(:tags, %i[name mission_id])
  end
end
