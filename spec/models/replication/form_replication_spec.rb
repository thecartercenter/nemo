require 'spec_helper'

describe Form do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'question rank change' do
    before do
      @std_form = create(:form, question_types: %w(integer integer integer integer), is_standard: true)
      @copy_form = @std_form.replicate(mode: :to_mission, dest_mission: get_mission)
      @old_copy_qing_ids = @copy_form.questionings.map(&:id)

      # Switch ranks on @std_form (swap ranks 1,2 and 3,4)
      ids = @std_form.questionings.map(&:id)
      @std_form.name = 'Updated ranks'
      @std_form.update_ranks({ids[1] => 1, ids[0] => 2, ids[3] => 3, ids[2] => 4})
      @std_form.save_and_rereplicate
    end

    it 'should replicate rank changes' do
      ids = @old_copy_qing_ids
      expect(@copy_form.reload.questionings.map(&:id)).to eq [ids[1], ids[0], ids[3], ids[2]]
    end
  end
end
