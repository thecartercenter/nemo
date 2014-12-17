# There are many more form replication tests in test/unit/standardizable
require 'spec_helper'

describe 'replicating a form' do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
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


    context 'old tests' do
      it "creating standard form should create standard questions and questionings" do
        # this factory includes some default questions
        f = FactoryGirl.create(:form, :is_standard => true)
        assert(f.reload.questions.all?(&:is_standard?))
      end

      it "adding questions to a std form should create standard questions and questionings" do
        f = FactoryGirl.create(:form, :is_standard => true)
        f.questions << FactoryGirl.create(:question, :is_standard => true)
        assert(f.reload.questions.all?(&:is_standard?))
      end

      it "replicating form within mission should avoid name conflict" do
        f = FactoryGirl.create(:form, :name => "Myform", :question_types => %w(integer select_one))
        f2 = f.replicate(:mode => :clone)
        assert_equal('Myform 2', f2.name)
        f3 = f2.replicate(:mode => :clone)
        assert_equal('Myform 3', f3.name)
        f4 = f3.replicate(:mode => :clone)
        assert_equal('Myform 4', f4.name)
      end

      it "replicating form within mission should produce different questionings but same questions and option set" do
        f = FactoryGirl.create(:form, :question_types => %w(integer select_one))
        f2 = f.replicate(:mode => :clone)
        assert_not_equal(f.questionings.first, f2.questionings.first)

        # questionings should point to proper form
        assert_equal(f.questionings[0].form, f)
        assert_equal(f2.questionings[0].form, f2)

        # questions and option sets should be same
        assert_equal(f.questions, f2.questions)
        assert_not_nil(f2.questions[1].option_set)
        assert_equal(f.questions[1].option_set, f2.questions[1].option_set)
      end

      it "replicating a standard form should do a deep copy" do
        f = FactoryGirl.create(:form, :question_types => %w(select_one integer), :is_standard => true)
        f2 = f.replicate(:mode => :to_mission, :dest_mission => get_mission)

        # mission should now be set and should not be standard
        assert(!f2.is_standard)
        assert_equal(get_mission, f2.mission)

        # all objects should be distinct
        assert_not_equal(f, f2)
        assert_not_equal(f.questionings[0], f2.questionings[0])
        assert_not_equal(f.questionings[0].question, f2.questionings[0].question)

        # but properties should be same
        assert_equal(f.questionings[0].rank, f2.questionings[0].rank)
        assert_equal(f.questionings[0].question.code, f2.questionings[0].question.code)
      end

      it "replicating form with conditions should produce correct new conditions" do
        f = FactoryGirl.create(:form, :question_types => %w(integer select_one))

        # create condition
        f.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'gt', :value => 1)

        # replicate and test
        f2 = f.replicate(:mode => :clone)

        # questionings and conditions should be distinct
        assert_not_equal(f.questionings[1], f2.questionings[1])
        assert_not_equal(f.questionings[1].condition, f2.questionings[1].condition)

        # new condition should point to new questioning
        assert_equal(f2.questionings[1].condition.ref_qing, f2.questionings[0])
      end

      it "replicating a standard form with a condition referencing an option should produce correct new option reference" do
        f = FactoryGirl.create(:form, :question_types => %w(select_one integer), :is_standard => true)

        # create condition with option reference
        f.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'eq',
          :option => f.questions[0].option_set.options[0])

        # replicate and test
        f2 = f.replicate(:mode => :to_mission, :dest_mission => get_mission)

        # questionings, conditions, and options should be distinct
        assert_not_equal(f.questionings[1], f2.questionings[1])
        assert_not_equal(f.questionings[1].condition, f2.questionings[1].condition)
        assert_not_equal(f.questionings[0].question.option_set.options[0], f2.questionings[0].question.option_set.options[0])

        # new condition should point to new questioning
        assert_equal(f2.questionings[1].condition.ref_qing, f2.questionings[0])

        # new condition should point to new option
        assert_not_nil(f2.questionings[1].condition.option)
        assert_not_nil(f2.questionings[0].question.option_set.options[0])
        assert_equal(f2.questionings[1].condition.option, f2.questionings[0].question.option_set.options[0])
      end

      it "replicating a form with multiple conditions should also work" do
        f = FactoryGirl.create(:form, :question_types => %w(integer integer integer integer))

        # create conditions
        f.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'gt', :value => 1)
        f.questionings[3].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[1], :op => 'gt', :value => 1)

        f2 = f.replicate(:mode => :clone)
        # new conditions should point to new questionings
        assert_equal(f2.questionings[1].condition.ref_qing, f2.questionings[0])
        assert_equal(f2.questionings[3].condition.ref_qing, f2.questionings[1])
      end
    end
  end

  describe 'clone' do
    context 'for a form with a parenth in its name' do
      before do
        @orig = create(:form, name: 'The (Form)')
      end

      it 'should work' do
        expect(@orig.replicate(mode: :clone).name).to eq 'The (Form) 2'
      end
    end
  end
end
