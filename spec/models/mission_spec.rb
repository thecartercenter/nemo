require 'spec_helper'

describe Mission do
  describe 'terminate' do
    before do
      @mission = create(:mission_with_full_heirarchy)
    end

    it 'should delete all objects in mission' do
      expect(obj_counts).to eq [1, 1, 1, 6, 2, 10, 13, 3, 1, 1, 5, 2]
      @mission.terminate
      expect(obj_counts).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end

    def obj_counts
      [Mission, Broadcast, Form, Question, QingGroup, Option,
        OptionNode, OptionSet, Report::Report, Response, Answer, Choice].map(&:count)
    end
  end
end
