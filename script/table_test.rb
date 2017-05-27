require 'active_support/core_ext/digest/uuid'

table_specification_path = Rails.root.join("db", "resources", "tables.yml")
puts "Loading #{table_specification_path}"
tables = YAML.load_file(table_specification_path)
global_namespace = Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "sassafras.coop")

tables.each do |table_name, table_data|
  table_namespace = Digest::UUID.uuid_v5(global_namespace, table_name)

  # Get the rails class for the table
  table_class = table_data["class"].constantize

  puts "#{table_name.upcase}:"

  table_class.find_each do |instance|
    # uuid for instance
    instance_id = instance.id.to_s
    uuid = Digest::UUID.uuid_v5(table_namespace, instance_id)

    puts "  #{table_name}[#{instance_id}]"
    puts "    id: #{uuid}"

    if table_data["foreign_keys"]
      table_data["foreign_keys"].each do |foreign_key_type, foreign_keys|
        foreign_keys.each do |foreign_key_column, target_table_data|
          if foreign_key_type == "polymorphic"
            target_table_name = instance.send(target_table_data["type_column"]).tableize
          else
            target_table_name = target_table_data
          end

          # Get id of referenced instance
          fk_id = instance.send(foreign_key_column)

          target_table_namespace = Digest::UUID.uuid_v5(global_namespace, target_table_name)

          # Generate UUID for instance
          fk_uuid = Digest::UUID.uuid_v5(target_table_namespace, fk_id.to_s) if fk_id.present?

          # for display
          fk_uuid = uuid.present? ? fk_uuid : "null"
          fk_id = fk_id.present? ? fk_id.to_s : "null"

          puts "      #{foreign_key_column}[#{target_table_name}](#{fk_id}): #{fk_uuid}"
        end
      end
    end
  end

  puts "\n\n"
end
