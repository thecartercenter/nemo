class SetOptionRanksAndRemoveOrderingAndValueColumns < ActiveRecord::Migration
  def up
    rank_assignment_succeeded = false
    
    transaction do
      # for each option set, get the option_settings in the old sorted order and set the new rank parameter according to that order
      OptionSet.all.each do |os|
        puts "processing option set #{os.id}: #{os.name}"
        
        # purge any option settings with nil for option
        os.option_settings.each do |o| 
          if o.option.nil?
            puts "purging option setting #{o.id} since it has no associated option"
            os.option_settings.destroy(o)
          end
        end
        
        # sort the option settings
        option_settings = os.option_settings.sort do |a,b|
          (a.option.value.to_i <=> b.option.value.to_i) * (os.ordering && os.ordering.match(/desc/) ? -1 : 1)
        end
        
        # assign ranks
        option_settings.each_with_index do |o, idx|
          puts "assigning rank #{idx + 1} to option #{o.option.id}: #{o.option.name}"
          o.rank = idx + 1
          o.save!
        end
      end
      
      # purge any option settings with no ranks
      count = OptionSetting.where(:rank => nil).delete_all
      puts "purged #{count} option settings with no rank"
      
      rank_assignment_succeeded = true
    end
    
    # now we can remove the old ordering and value columns
    if rank_assignment_succeeded
      remove_column :option_sets, :ordering
      remove_column :options, :value
    end
  end

  def down
  end
end
