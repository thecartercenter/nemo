# There are many more form replication tests in test/unit/standardizable
require 'spec_helper'

describe Form do
  before(:all) do
    @mission1 = create(:mission)
    @mission2 = create(:mission)
  end

  describe 'to_mission' do
    context 'with nested questions' do
      before do
        @std = create(:form, question_types: ['integer', %w(select_one integer)], is_standard: true)
        @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
        @copy.reload
      end

      it 'should not produce blank ancestry (only nil)' do
        expect(@copy.root_group.ancestry).to be_nil
      end

      it 'should produce distinct child objects' do
        expect(@std).not_to eq @copy
        expect(@std.root_group).not_to eq @copy.root_group
        expect(@std.c[1]).not_to eq @copy.c[1]
        expect(@std.c[1].c[1]).not_to eq @copy.c[1].c[1]
      end

      it 'should produce correct form references' do
        expect(@copy.root_group.form).to eq @copy
        expect(@copy.c[0].form).to eq @copy
        expect(@copy.c[1].c[0].form).to eq @copy
      end
    end

    context 'with an existing copy of form in mission' do
      before do
        @std = create(:form, question_types: %w(select_one integer), is_standard: true)
        @copy1 = @std.replicate(mode: :to_mission, dest_mission: get_mission)
        @copy2 = @std.replicate(mode: :to_mission, dest_mission: get_mission)
      end

      it 'should create a second copy but re-use questions, option sets' do
        expect(@copy1).not_to eq @copy2
        expect(@copy1.c[0]).not_to eq @copy2.c[0]
        expect(@copy1.c[0].question).to eq @copy2.c[0].question
        expect(@copy1.c[0].question.option_set).to eq @copy2.c[0].question.option_set
      end
    end

    context 'with a condition referencing an option' do
      context 'from a multilevel set' do
        before do
          @std = create(:form, question_types: %w(select_one integer), is_standard: true, use_multilevel_option_set: true)

          # Create condition on 2nd questioning.
          @std.c[1].condition = build(:condition,
            ref_qing: @std.c[0], op: 'eq',
            option_ids: [@std.questions[0].option_set.c[1].option_id, @std.questions[0].option_set.c[1].c[0].option_id])
          @std.c[1].condition.save!
        end

        context 'if all goes well' do
          before do
            @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
            @copy_cond = @copy.c[1].condition
            @copy_opt_set = @copy.c[0].option_set
          end

          it 'should produce distinct child objects' do
            expect(@std.c[1]).not_to eq @copy.c[1]
            expect(@std.c[1].condition).not_to eq @copy_cond
            expect(@std.c[0].options[0]).not_to eq @copy_opt_set.options[0]
          end

          it 'should produce correct condition-qing link' do
            expect(@copy_cond.ref_qing).to eq @copy.c[0]
          end

          it 'should produce correct new option references' do
            expect(@copy_cond.option_ids).to eq([@copy_opt_set.c[1].option_id, @copy_opt_set.c[1].c[0].option_id])
          end
        end

        context 'if option is not found' do
          before do
            # First replicate the option set and destroy the option.
            @copy_os = @std.c[0].option_set.replicate(mode: :to_mission, dest_mission: get_mission)
            @copy_os.c[1].c[0].option.destroy

            # Now replicate the form.
            @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
          end

          it 'should delete the condition' do
            expect(@copy.c[1].condition).to be_nil
          end
        end
      end
    end

    context 'with a condition referencing a now-incompatible question' do
      before do
        @std = create(:form, question_types: %w(select_one integer), is_standard: true)

        # Create condition.
        @std.c[1].condition = build(:condition, ref_qing: @std.c[0], op: 'eq',
          option_ids: [@std.c[0].question.option_set.c[1].option_id])
        @std.c[1].condition.save!

        # Replicate question first and render the copy incompatible.
        @orig_q1 = @std.c[0].question
        @copy_q1 = @orig_q1.replicate(mode: :to_mission, dest_mission: @mission1)
        @copy_q1.option_set = create(:option_set, mission: @mission1)
        @copy_q1.save!

        # Replicate form.
        @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
        @copy_q1.reload
      end

      it 'should make a new copy of the question and link properly' do
        # Link should get erased when becoming incompatible.
        expect(@copy_q1.original_id).to be_nil
        expect(@copy_q1.standard_copy?).to be false

        # New question copy should have been created.
        expect(@copy.c[0].question).not_to eq @copy_q1
        expect(@copy.c[0].question.original).to eq @std.c[0].question
        expect(@copy.c[0].question.standard_copy?).to be true

        # Condition should point to newer question copy.
        expect(@copy.c[1].condition.ref_qing).to eq @copy.c[0]
        expect(@copy.c[1].condition.options).not_to be_empty
      end
    end
  end

  describe 'clone' do

    context 'basic' do
      before do
        @orig = create(:form, question_types: ['integer', %w(select_one integer)], is_standard: true)
        @copy = @orig.replicate(mode: :clone)
        @copy.reload
      end

      it 'should reuse only standardizable objects' do
        expect(@orig).not_to eq @copy
        expect(@orig.root_group).not_to eq @copy.root_group
        expect(@orig.c[0]).not_to eq @copy.c[0]
        expect(@orig.c[0].question).to eq @copy.c[0].question # Standardizable
        expect(@orig.c[1].c[0]).not_to eq @copy.c[1].c[0]
      end

      it 'should produce correct form references' do
        expect(@copy.root_group.form).to eq @copy
        expect(@copy.c[0].form).to eq @copy
        expect(@copy.c[1].c[0].form).to eq @copy
      end
    end

    context 'for multiple clones' do
      before do
        @f1 = create(:form, name: "Myform")
        @f2 = @f1.replicate(mode: :clone)
        @f3 = @f2.replicate(mode: :clone)
        @f4 = @f3.replicate(mode: :clone)
      end

      it 'should avoid name collisions' do
        expect(@f2.name).to eq 'Myform 2'
        expect(@f3.name).to eq 'Myform 3'
        expect(@f4.name).to eq 'Myform 4'
      end
    end

    context 'for a form with a parenth in its name' do
      before do
        @orig = create(:form, name: 'The (Form)')
        @copy = @orig.replicate(mode: :clone)
      end

      it 'should work' do
        expect(@copy.name).to eq 'The (Form) 2'
      end
    end
  end
end
