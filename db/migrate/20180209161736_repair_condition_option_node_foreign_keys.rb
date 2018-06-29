class RepairConditionOptionNodeForeignKeys < ActiveRecord::Migration[4.2]
  def up
    transaction do
      puts "Repairing condition -> option node links"
      broken = Condition.with_deleted.joins(:option_node).
        where("conditions.mission_id != option_nodes.mission_id").to_a
      puts "#{broken.size} broken links found"
      broken.each do |c|
        incorrect = c.option_node
        if oset = c.ref_qing.option_set
          correct = oset.descendants.where(original_id: incorrect.original_id).first
          if correct
            puts "#{incorrect.id} --> #{correct.id}"
            c.option_node_id = correct.id
          else
            puts "CORRECT NODE NOT FOUND FOR CONDITION #{c.id}. SKIPPING. FURTHER ACTION NEEDED. "\
              "EITHER THE CONDITION NEEDS TO BE DESTROYED OR THE REFERRED OPTION SET NEEDS TO BE "\
              "MANUALLY IMPORTED TO THE MISSION AND THE LINK MANUALLY REPAIRED."
          end
        else
          puts "N option set found for ref_qing of #{c.id}. This is a corruption. Nullifying option_node_id."
          c.option_node_id = nil
        end
        c.save(validate: false)
      end
    end
  end
end
