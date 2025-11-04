class DeleteWeirdConditionOptionNodesTable < ActiveRecord::Migration[4.2]
  def up
    execute("DROP TABLE condition_option_nodes")
  rescue StandardError
  end
end
