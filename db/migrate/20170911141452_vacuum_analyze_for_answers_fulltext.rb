class VacuumAnalyzeForAnswersFulltext < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    execute("VACUUM ANALYZE") # Needed for the DB to really use the index in our searches.
  end

  def down
  end
end
