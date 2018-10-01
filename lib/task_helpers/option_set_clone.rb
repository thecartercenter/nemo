class OptionSetClone
  def run
    Rails.logger.debug("finding option sets with duplicate root nodes")
    duplicate_root_node_ids = OptionSet.all.group(:root_node_id).count.select { |id, count| count > 1 }.keys
    Rails.logger.debug("#{duplicate_root_node_ids.count} found")

    duplicate_root_node_ids.each do |root_node_id|
      option_sets = OptionSet.where(root_node_id: root_node_id).where("original_id IS NOT NULL")
      option_sets.each do |option_set|
        Rails.logger.debug("cloning option set #{option_set.id}")
        copy = option_set.replicate(mode: :clone)
        Rails.logger.debug("cloned to #{copy.id}")

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
  end
end
