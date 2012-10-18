class DumpOldReports < ActiveRecord::Migration
  def up
    # ensure tmp directory
    dir = File.join(Rails.root, "tmp")
    Dir.mkdir(dir) unless File.exists?(dir)
    
    # output data
    File.open(File.join(dir, "old_reports.yml"), "w") do |f|
      %w(reports groupings aggregations fields response_attributes).each do |tbl|
        full_tbl = "report_#{tbl}"
        f.puts("# #{full_tbl}")
        res = execute("SELECT * FROM #{full_tbl}")
        while row = res.fetch_hash do
          f.puts(row.to_yaml)
        end
        f.puts("\n")
      end
    end
  end

  def down
  end
end
