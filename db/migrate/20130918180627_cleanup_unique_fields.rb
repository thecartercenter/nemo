class CleanupUniqueFields < ActiveRecord::Migration[4.2]
  def up
    # Now obsolete
    #
    # transaction do
    #   # make sure all unique fields are unique per mission, and trim any whitespace
    #   [[Form, :name, :sep_words], [OptionSet, :name, :sep_words], [Question, :code, :camel_case]].each do |spec|
    #     spec[0].includes(:mission).all.each do |o|
    #       puts "checking #{spec[0].name} '#{o.send(spec[1])}' in mission '#{o.mission ? o.mission.name : 'STD'}'"
    #
    #       # trim any whitespace
    #       o.send("#{spec[1]}=", o.send(spec[1]).strip)
    #
    #       # change the field to a unique
    #       o.send("#{spec[1]}=", o.generate_unique_field_value(:mission => o.mission, :dest_obj => o, :field => spec[1], :style => spec[2]))
    #
    #       if o.send("#{spec[1]}_changed?")
    #         old_val = o.send("#{spec[1]}_was")
    #         new_val = o.send(spec[1])
    #         puts "changing '#{old_val}' to '#{new_val}'"
    #       end
    #
    #       o.save(:validate => false)
    #     end
    #   end
    # end
  end

  def down
  end
end
