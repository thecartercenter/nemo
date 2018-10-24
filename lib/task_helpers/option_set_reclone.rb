# frozen_string_literal: true

# Re-clones any Option Sets that didn't clone properly originally due to bug #7479.
class OptionSetReclone
  def run
    Rails.logger.debug("finding option sets with duplicate root nodes")
    duplicate_root_node_ids = OptionSet.all.group(:root_node_id).count.select { |id, count| count > 1 }.keys
    Rails.logger.debug("#{duplicate_root_node_ids.count} found")

    recloned = []

    duplicate_root_node_ids.each do |root_node_id|
      option_sets = OptionSet.where(root_node_id: root_node_id).where("original_id IS NOT NULL")
      option_sets.each do |option_set|
        Rails.logger.debug("re-cloning option set #{option_set.id} (original #{option_set.original_id})")
        copy = option_set.original.replicate(mode: :clone)
        recloned << copy
        Rails.logger.debug("re-cloned to #{copy.id}")

        # update all references to the old option set
        referencing_models = [
          Question,
          Report::OptionSetChoice
        ]

        referencing_models.each do |model|
          Rails.logger.debug("updating referencing #{model} records for #{copy.id}")
          records = model.where(option_set_id: option_set.id)
          records.update_all(option_set_id: copy.id)
        end

        # destroy old option set
        Rails.logger.debug("destroying option set #{option_set.id}")
        option_set.destroy!
      end
    end

    recloned
  end
end
