# frozen_string_literal: true

# TODO: This class needs tests
module Cloning
  # Imports from CSV ZIP bundle.
  class Importer
    attr_accessor :zip_file

    def initialize(zip_file)
      self.zip_file = zip_file
    end

    def import
      ApplicationRecord.transaction do
        # Defer constraints so that constraints are not checked until all data is loaded.
        SqlRunner.instance.run("SET CONSTRAINTS ALL DEFERRED")
        Zip::InputStream.open(zip_file) do |io|
          index = 0
          while (entry = io.get_next_entry)
            class_name = entry.name.match(/\A(\w+)-\d+\.csv\z/)[1]
            klass = class_name.sub(/.csv$/, "").tr("_", ":").constantize
            tmp_table = "tmp_table_#{index}"
            SqlRunner.instance.run("CREATE TEMP TABLE #{tmp_table}
              ON COMMIT DROP AS SELECT * FROM #{klass.table_name} WITH NO DATA")
            klass.copy_from(io, table: tmp_table)
            col_names = klass.column_names - %w[standard_copy last_mission_id]
            select = col_names == klass.column_names ? "*" : col_names.join(", ")
            insert_cols = col_names == klass.column_names ? "" : "(#{col_names.join(', ')})"
            SqlRunner.instance.run("INSERT INTO #{klass.table_name}#{insert_cols}
              SELECT #{select} FROM #{tmp_table} ON CONFLICT DO NOTHING")
            index += 1
          end
        end
      end
    end
  end
end
