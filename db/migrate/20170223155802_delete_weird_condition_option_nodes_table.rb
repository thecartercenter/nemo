class DeleteWeirdConditionOptionNodesTable < ActiveRecord::Migration[4.2]
  def up
    begin
      execute("DROP TABLE condition_option_nodes")
    rescue
    end
  end
end
