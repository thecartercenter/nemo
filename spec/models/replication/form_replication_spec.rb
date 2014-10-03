require 'spec_helper'

describe Form do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'question rank change' do
    context 'without conditions' do
      before do
        @std_form = create(:form, question_types: %w(integer integer integer integer), is_standard: true)
        @copy_form = @std_form.replicate(mode: :to_mission, dest_mission: get_mission)
        @old_copy_qing_ids = @copy_form.questionings.map(&:id)

        # Switch ranks on @std_form (swap ranks 1,2 and 3,4)
        ids = @std_form.questionings.map(&:id)
        @std_form.name = 'Updated ranks' # Update name to ensure save
        @std_form.update_ranks({ids[1] => 1, ids[0] => 2, ids[3] => 3, ids[2] => 4})
        @std_form.save_and_rereplicate
      end

      it 'should replicate rank changes' do
        ids = @old_copy_qing_ids
        expect(@copy_form.reload.questionings.map(&:id)).to eq [ids[1], ids[0], ids[3], ids[2]]
      end
    end

    context 'with condition' do
      before do
        @std_form = create(:form, question_types: %w(select_one integer integer), is_standard: true)
        @std_form.questionings[2].create_condition(ref_qing: @std_form.questionings[0], op: 'eq',
          option_id: @std_form.questionings[0].options[0].id)
        @copy_form = @std_form.replicate(mode: :to_mission, dest_mission: get_mission)
        @old_copy_qing_ids = @copy_form.questionings.map(&:id)

        # Move middle question to top.
        ids = @std_form.questionings.map(&:id)

        # Without these, the test was not triggering an error that was happening in the wild.
        @std_form.reload
        @copy_form.reload

        @std_form.name = 'Updated ranks' # Update name to ensure save
        @std_form.update_ranks({ids[0] => 2, ids[1] => 1, ids[2] => 3})
        @std_form.save_and_rereplicate!
      end

      it 'should replicate rank changes' do
        ids = @old_copy_qing_ids
        expect(@copy_form.reload.questionings.map(&:id)).to eq [ids[1], ids[0], ids[2]]

        # Ref qing should not have changed.
        expect(@copy_form.questionings[2].condition.ref_qing_id).to eq ids[0]
      end
    end
  end

  describe 'hidden std copy question' do
    before do
      @std_form = create(:form, question_types: %w(integer integer), is_standard: true)
      @copy_form = @std_form.replicate(mode: :to_mission, dest_mission: get_mission)

      # Hide a copied question.
      @copy_form.questionings[1].update_attributes(hidden: true)
      @std_form.save_and_rereplicate!
      @copy_form.reload
    end

    it 'should not get unhidden on rereplicate' do
      expect(@copy_form.questionings.map(&:hidden)).to eq [false, true]
    end
  end
end
