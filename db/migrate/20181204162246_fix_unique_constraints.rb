# frozen_string_literal: true

class FixUniqueConstraints < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Migration.suppress_messages do
      indices = [{
        table: :assignments,
        resolve_by: :highest_role,
        cols: %w[deleted_at mission_id user_id]
      }, {
        table: :forms,
        resolve_by: :manual,
        cols: %w[root_id]
      }, {
        table: :form_items,
        resolve_by: :manual,
        cols: %w[form_id question_id]
      }, {
        table: :form_versions,
        resolve_by: :manual,
        cols: %w[code deleted_at]
      }, {
        table: :missions,
        resolve_by: :manual,
        cols: %w[shortcode deleted_at]
      }, {
        table: :missions,
        resolve_by: :num_suffix,
        col_for_suffix: :compact_name,
        cols: %w[compact_name]
      }, {
        table: :option_sets,
        resolve_by: :manual,
        cols: %w[root_node_id]
      }, {
        table: :questions,
        resolve_by: :num_suffix,
        cols: %w[mission_id code deleted_at]
      }, {
        table: :responses,
        resolve_by: :manual,
        cols: %w[form_id odk_hash deleted_at]
      }, {
        table: :responses,
        resolve_by: :manual,
        cols: %w[shortcode deleted_at]
      }, {
        table: :settings,
        resolve_by: :manual,
        cols: %w[mission_id],
        no_deleted_at: true
      }, {
        table: :user_group_assignments,
        resolve_by: :delete_extra,
        cols: %w[user_id user_group_id deleted_at]
      }, {
        table: :user_groups,
        resolve_by: :num_suffix,
        col_for_suffix: :name,
        cols: %w[name mission_id deleted_at]
      }, {
        table: :users,
        resolve_by: :num_suffix,
        col_for_suffix: :login,
        cols: %w[login deleted_at]
      }, {
        table: :users,
        resolve_by: :manual,
        cols: %w[sms_auth_code deleted_at]
      }]

      ActiveRecord::Base.transaction do
        manual_conflicts = false
        indices.each do |index|
          index[:new_cols] = index[:cols] - ["deleted_at"]
          puts "Checking index #{index[:table]}(#{index[:new_cols].join(', ')})"

          remove_index(index[:table], index[:cols]) if index_exists?(index[:table], index[:cols])

          if (groups = dupe_groups(index)).any?
            groups.map! { |g| g["ids"][1...-1].split(",") } # Convert to arrays of IDs
            send(index[:resolve_by], index, groups)
            manual_conflicts = true if index[:resolve_by] == :manual
          end

          unless groups.any? && index[:resolve_by] == :manual
            add_index(index[:table], index[:new_cols], unique: true, where: deleted_where(index))
          end
        end

        if manual_conflicts
          raise "There were manual conflicts that need to be resolved before this migration can"\
            "complete. Please resolve them and run migrations again.\n\n"
        end
      end
    end
  end

  private

  def dupe_groups(index)
    null_where = index[:new_cols].map { |c| "#{c} IS NOT NULL" }.join(" AND ")
    wheres = [null_where, deleted_where(index)].compact.join(" AND ")
    query = "SELECT array_agg(id) AS ids FROM #{index[:table]} "\
      "WHERE #{wheres} GROUP BY #{index[:new_cols].join(', ')} HAVING COUNT(*) > 1"
    execute(query).to_a
  end

  def deleted_where(index)
    index[:no_deleted_at] ? nil : "deleted_at IS NULL"
  end

  def manual(index, id_groups)
    id_groups.each do |ids|
      print_status_message(ids, "***** NEEDS MANUAL RESOLUTION *****", show_id_list: false)
      puts("  Affected rows:")
      id_list = ids.map { |id| "'#{id}'" }.join(",")
      query = "SELECT id, #{index[:new_cols].join(', ')} FROM #{index[:table]} WHERE id IN (#{id_list})"
      execute(query).to_a.each do |row|
        puts("  - #{row.inspect}")
      end
    end
  end

  def delete_extra(index, id_groups)
    id_groups.each do |ids|
      print_status_message(ids, "Deleting extra records.")
      id_list = ids[1..-1].map { |id| "'#{id}'" }.join(",")
      execute("DELETE FROM #{index[:table]} WHERE id IN (#{id_list})")
    end
  end

  def highest_role(index, id_groups)
    id_groups.each do |ids|
      print_status_message(ids, "Taking highest role.")
      id_list = ids.map { |id| "'#{id}'" }.join(",")
      rows = execute("SELECT id, role FROM #{index[:table]} WHERE id IN (#{id_list})").to_a
      rows.sort_by { |row| User::ROLES.index(row["role"]) }
      puts(+"  Roles found: " << rows.map { |row| row["role"] }.join(", "))
      ids_to_delete = rows[1..-1].map { |row| "'#{row['id']}'" }.join(",")
      puts("  Deleting ids #{ids_to_delete}".delete("'"))
      execute("DELETE FROM assignments WHERE id IN (#{ids_to_delete})")
    end
  end

  def num_suffix(index, id_groups)
    col = index[:col_for_suffix]
    id_groups.each do |ids|
      print_status_message(ids, "Adding numeric suffixes.")
      value = execute("SELECT #{col} FROM #{index[:table]} WHERE id = '#{ids.first}'").to_a[0][col.to_s]
      puts("  Duplicate value: #{value}")
      suffix = 2

      ids[1..-1].each do |id|
        while execute("SELECT id FROM #{index[:table]} WHERE #{col} = '#{value}#{suffix}'").to_a.any?
          suffix += 1
        end
        puts("  Updating #{id} to #{value}#{suffix}")
        execute("UPDATE #{index[:table]} SET #{col} = '#{value}#{suffix}' WHERE id = '#{id}'")
        suffix += 1
      end
    end
  end

  def print_status_message(ids, msg, show_id_list: true)
    puts("  Duplicates detected.")
    if show_id_list
      id_list = ids.map { |id| "    #{id}" }.join("\n")
      puts("  Affected IDs:\n#{id_list}")
    end
    puts("  #{msg}")
  end
end
