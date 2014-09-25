# There are many more form replication tests in test/unit/standardizable
require 'spec_helper'

describe 'replicating a form' do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  context 'on create' do
    context 'with a condition referencing an option' do
      context 'from a multilevel set' do
        before(:all) do
          @std = create(:form, question_types: %w(select_one integer), is_standard: true, use_multilevel_option_set: true)
          @std.questionings[1].condition = build(:condition,
            ref_qing: @std.questionings[0], op: 'eq',
            option_ids: [@std.questions[0].option_set.c[1].option_id, @std.questions[0].option_set.c[1].c[0].option_id])
          @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
          @copy_cond = @copy.questionings[1].condition
          @copy_opt_set = @copy.questionings[0].option_set
        end

        it 'should produce distinct child objects' do
          expect(@std.questionings[1]).not_to eq @copy.questionings[1]
          expect(@std.questionings[1].condition).not_to eq @copy_cond
          expect(@std.questionings[0].options[0]).not_to eq @copy_opt_set.options[0]
        end

        it 'should produce correct condition-qing link' do
          expect(@copy_cond.ref_qing).to eq @copy.questionings[0]
        end

        it 'should produce correct new option references' do
          expect(@copy_cond.option_ids).to eq([@copy_opt_set.c[1].option_id, @copy_opt_set.c[1].c[0].option_id])
        end
      end
    end
  end

  context 'on update' do
    context 'when question rank changes' do
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
end
