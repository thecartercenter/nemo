class FormItem < ActiveRecord::Base
  include MissionBased, FormVersionable, Replication::Replicable
  belongs_to(:form, :inverse_of => :questionings)

  before_create(:set_mission)

  has_ancestry cache_depth: true

  private

    # copy mission from question
    def set_mission
      self.mission = form.try(:mission)
    end

end
