# There are many more form replication tests in test/unit/standardizable
require 'spec_helper'

describe 'replicating a form' do
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
