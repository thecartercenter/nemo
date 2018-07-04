require "active_support/core_ext/digest/uuid"

class MigratePrimaryKeysToUuid < ActiveRecord::Migration[4.2]
  TABLE_SPECIFICATION_PATH = Rails.root.join("db", "resources", "tables.yml")
  TABLES = YAML.load_file(TABLE_SPECIFICATION_PATH)
  GLOBAL_NAMESPACE = Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "sassafras.coop")

  def up
    enable_extension "uuid-ossp"
    transaction do
      # manually remove extra foreign keys first
      to_remove = [
        [:forms, "forms_original_id_fkey1"],
        [:option_nodes, "option_nodes_original_id_fkey1"],
        [:option_sets, "option_sets_original_id_fkey1"],
        [:questions, "questions_original_id_fkey1"]
      ]
      to_remove.each { |t, n| p foreign_keys(t).map(&:name); remove_foreign_key(t, name: n) if foreign_keys(t).map(&:name).include?(n) }

      TABLES.each do |table_name, table_data|
        # Seek out and clean orphaned records
        clean_orphans(table_name, table_data) if table_data["clean_orphans"]
      end

      TABLES.each do |table_name, table_data|
        # then remove foreign keys from all tables
        remove_all_foreign_keys(table_name, table_data)

        # then remove indexes
        remove_all_indexes(table_name)

        # create new ID column
        add_column table_name, :pk_uuid, :uuid, default: "uuid_generate_v4()"

        # Lengthen ancestry column if available
        change_column table_name, :ancestry, :text if table_data["ancestry"]

        # create uuid foreign key columns
        create_new_columns(table_name, table_data)
      end

      TABLES.each do |table_name, table_data|
        # UUID Namespace for Current Table
        table_namespace = Digest::UUID.uuid_v5(GLOBAL_NAMESPACE, table_name)

        # Get the rails class for the table
        table_class = table_data["class"].constantize

        # reload column information
        table_class.connection.schema_cache.clear!
        table_class.reset_column_information

        # populate new UUID fields
        puts "TABLE: #{table_class}"
        table_class.find_each do |instance|
          default = {pk_uuid: Digest::UUID.uuid_v5(table_namespace, instance.id.to_s)}
          instance_params = default.merge(populate_foreign_key_fields(instance, table_name, table_data))
          instance_params[:ancestry] = rewrite_ancestry_field(instance, table_namespace) if table_data["ancestry"]
          instance.update_columns(instance_params)
        end

        # Set new primary key
        rename_column table_name, :id, :old_id
        rename_column table_name, :pk_uuid, :id
        execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{table_name}_pkey;"
        execute "ALTER TABLE #{table_name} ADD PRIMARY KEY (id);"
        change_column_null table_name, :old_id, true
        change_column_default table_name, :old_id, nil
      end

      TABLES.each do |table_name, table_data|
        # Set foreign keys back
        add_all_foreign_keys(table_name, table_data)

        # Add indexes
        add_foreign_key_indexes(table_name, table_data)
        add_additional_indexes(table_name, table_data)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def add_foreign_key_indexes(table_name, table_data)
    return unless table_data["foreign_keys"]

    # add indexes for foreign keys
    table_data["foreign_keys"].each do |foreign_key_type, foreign_key_data|
      foreign_key_data.each do |foreign_key_column, foreign_key_metadata|
        add_index table_name.to_sym, foreign_key_column
      end
    end
  end

  def add_additional_indexes(table_name, table_data)
    return unless table_data["indexes"]

    # add specified indexes
    table_data["indexes"].each do |index, index_data|
      options = {}
      options[:name] = index_data["name"] if index_data["name"].present?
      options[:unique] = index_data["unique"] if index_data["unique"].present?
      add_index table_name.to_sym, index_data["fields"], options
    end
  end

  def remove_all_indexes(table_name)
    indexes(table_name.to_sym).each do |index|
      remove_index table_name.to_sym, name: index.name
    end
  end

  def remove_all_foreign_keys(table_name, table_data)
    # only get actual foreign keys
    return unless table_data["foreign_keys"] && table_data["foreign_keys"]["actual"]
    table_data["foreign_keys"]["actual"].each do |foreign_key_column, foreign_key_data|
      foreign_table = foreign_key_data["foreign_table"]

      if foreign_keys(table_name.to_sym).any? { |fk| fk[:options][:column] == foreign_key_column }
        puts "  Removing foreign key #{foreign_key_column} to #{foreign_table}"
        remove_foreign_key table_name.to_sym, column: foreign_key_column.to_sym
      end
    end
  end

  def add_all_foreign_keys(table_name, table_data)
    return unless table_data["foreign_keys"] && table_data["foreign_keys"]["actual"]
    table_data["foreign_keys"]["actual"].each do |foreign_key_column, foreign_key_data|
      # Set up additional data
      foreign_table = foreign_key_data["foreign_table"]
      on_delete = foreign_key_data["on_delete"] || :restrict
      on_update = foreign_key_data["on_update"] || :restrict

      puts "  Adding foreign key #{foreign_key_column} to #{foreign_table}"
      add_foreign_key table_name.to_sym, foreign_table,
        column: foreign_key_column.to_sym,
        on_delete: on_delete.to_sym,
        on_update: on_update.to_sym,
        name: foreign_key_data["name"]
    end
  end

  def create_new_columns(table_name, table_data)
    return unless table_data["foreign_keys"]
    table_data["foreign_keys"].each do |foreign_key_type, foreign_key_data|
      foreign_key_data.each do |foreign_key_column, foreign_key_metadata|
        rename_column table_name, foreign_key_column, backup_column_name(foreign_key_column)
        change_column_null table_name, backup_column_name(foreign_key_column), true
        add_column table_name, foreign_key_column, :uuid
      end
    end
  end

  def rewrite_ancestry_field(instance, table_namespace)
    return unless instance.ancestry.present?
    puts "  Rewriting ancestry for #{instance.id}"

    ancestor_ids = instance.ancestry.split("/")
    ancestor_ids = ancestor_ids.map { |id| Digest::UUID.uuid_v5(table_namespace, id.to_s) }
    ancestor_ids.join("/")
  end

  def populate_foreign_key_fields(instance, table_name, table_data)
    puts "POPULATING INSTANCE #{instance.id} of #{table_name.titleize}"
    return {} unless table_data["foreign_keys"]
    instance_params = {}

    table_data["foreign_keys"].each do |foreign_key_type, foreign_key_data|
      case foreign_key_type
      when "actual"
        foreign_key_data.each do |foreign_key_column, foreign_key_metadata|
          foreign_table = foreign_key_metadata["foreign_table"]

          # Get UUID namespace for foreign table
          table_namespace = Digest::UUID.uuid_v5(GLOBAL_NAMESPACE, foreign_table)

          # Get value of old id
          old_id = instance[backup_column_name(foreign_key_column).to_sym]

          if old_id.present?
            # Transform into UUID
            uuid = Digest::UUID.uuid_v5(table_namespace, old_id.to_s)

            instance_params[foreign_key_column] = uuid
          end
        end
      when "polymorphic"
        foreign_key_data.each do |foreign_key_column, polymorphic_data|
          foreign_table = instance[polymorphic_data["type_column"]].tableize
          table_namespace = Digest::UUID.uuid_v5(GLOBAL_NAMESPACE, foreign_table)

          # get value of old id
          old_id = instance[backup_column_name(foreign_key_column).to_sym]

          if old_id.present?
            # Transform into UUID
            uuid = Digest::UUID.uuid_v5(table_namespace, old_id.to_s)

            instance_params[foreign_key_column] = uuid
          end
        end
      end
    end

    instance_params
  end

  def backup_column_name(column_name)
    column_without_id = column_name.chomp("_id")
    "#{column_without_id}_old_id"
  end

  def clean_orphans(table_name, table_data)
    puts "CLEAN ORPHANS FOR #{table_name}"
    return unless table_data["foreign_keys"] && table_data["foreign_keys"]["actual"]
    table_class = table_data["class"].constantize

    # for each foreign key relationship
    table_data["foreign_keys"]["actual"].each do |foreign_key_column, foreign_key_metadata|
      foreign_table_class = foreign_key_metadata["foreign_class"].constantize

      orphans = table_class.where.not(foreign_key_column => foreign_table_class.all)
      orphans.each do |orphan|
        if foreign_key_metadata["clean_method"] == "nullify"
          puts "NULLIFY ORPHAN"
          orphan.update_columns(foreign_key_column => nil)
        else
          puts "DELETE ORPHAN"
          orphan.delete
        end
      end
    end
  end
end
