class FormItem < ActiveRecord::Base
  include MissionBased, FormVersionable, Standardizable, Replicable  
  belongs_to(:form, :inverse_of => :questionings)

  before_create(:set_rank)
  before_create(:set_mission)
  after_destroy(:fix_ranks)

  # returns any questionings appearing before this one on the form
  def previous
    form.questionings.reject{|q| !rank.nil? && (q == self || q.rank > rank)}
  end

  private
    # sets rank if not already set
    def set_rank
      self.rank ||= (form.try(:max_rank) || 0) + 1
      return true
    end

    # copy mission from question
    def set_mission
      self.mission = form.try(:mission)
    end

    # repair the ranks of the remaining questions on the form
    def fix_ranks
      form.fix_ranks
    end
end
