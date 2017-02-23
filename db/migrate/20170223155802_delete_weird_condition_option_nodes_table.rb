class DeleteWeirdConditionOptionNodesTable < ActiveRecord::Migration
  def up
    begin
      execute("DROP TABLE condition_option_nodes")
    rescue
    end
  end
end
