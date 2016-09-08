require 'spec_helper'

describe Mission do
  describe 'terminate' do
    before do
      @mission = create(:mission_with_full_heirarchy)
    end

    it 'should delete all objects in mission' do
      expect(obj_counts).to eq [1, 1, 3, 1, 6, 2, 10, 13, 3, 1, 1, 5, 2, 1, 2, 3]
      @mission.terminate
      expect(obj_counts).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end

    def obj_counts
      [Mission, Broadcast, Assignment, Form, Question, QingGroup, Option, OptionNode, OptionSet,
        Report::Report, Response, Answer, Choice, Sms::Message, UserGroup, UserGroupAssignment].map(&:count)
    end
  end
end
