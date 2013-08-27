module Replicable
  extend ActiveSupport::Concern

  # creates a duplicate in this or another mission
  def replicate(to_mission = nil, options = {})
    # default to current mission if not specified
    to_mission ||= mission if respond_to?(:mission)
    
    dont_copy = %w(id created_at updated_at mission_id is_standard standard_id)

    # copy the specified attribs
    copy = self.class.new
    attributes.except(*dont_copy).each{|k,v| copy.send("#{k}=", v)}

    # replicate associations
    #copy.option = option.replicate(to_mission, options)

    # set the proper mission if applicable
    copy.mission = to_mission if respond_to?(:mission)

    # if this is a standard obj, set the copy's standard to this
    copy.standard = self if is_standard?

    # save and return
    copy.save!
    copy
  end

end