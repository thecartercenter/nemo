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

      context 'when using eager loaded values from form items query' do
        it 'keeps the questioning count consistent' do
          std_qing_count = form_items_qing_count(@std)
          copy1_qing_count = form_items_qing_count(@copy1)
          copy2_qing_count = form_items_qing_count(@copy2)

          expect(std_qing_count).to eq copy1_qing_count
          expect(std_qing_count).to eq copy2_qing_count
        end
      end
    end

    context 'with a condition referencing an option' do
      context 'from a multilevel set' do
        before do
          @std = create(:form, question_types: %w(multilevel_select_one integer), is_standard: true)

          # Create condition on 2nd questioning.
          @std.c[1].condition = build(:condition,
            ref_qing: @std.c[0], op: 'eq',
            option_node_id: @std.questions[0].option_set.c[1].c[0].id)
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
            expect(@std.c[1].condition.option_node).not_to eq @copy_cond.option_node
          end

          it 'should produce correct condition-qing link' do
            expect(@copy_cond.ref_qing).to eq @copy.c[0]
          end

          it 'should produce correct new option node reference' do
            expect(@copy_cond.option_node_id).to eq(@copy_opt_set.c[1].c[0].id)
            expect(@copy_cond.option_node.option).to eq(@copy_opt_set.c[1].c[0].option)
            expect(@copy_cond.option_node.option_name).to eq "Tulip"
          end
        end

        context 'if the option has since been deleted in the mission' do
          before do
            # Replicate just the OptionSet into the mission
            os_copy = @std.questions[0].option_set.replicate(mode: :to_mission, dest_mission: get_mission)

            # Now delete the copy of the option node that is referenced by the condition
            os_copy.c[1].c[0].destroy
          end

          let!(:copy) { @std.replicate(mode: :to_mission, dest_mission: get_mission) }

          it 'should succeed but not copy the condition' do
            # Question should still be copied but copy should not have a condition
            expect(copy.c[1].code).to eq @std.c[1].code
            expect(@std.c[1].condition).to be_present
            expect(copy.c[1].condition).to be_nil
          end
        end
      end
    end

    context 'with a condition referencing a now-incompatible question' do
      before do
        @std = create(:form, question_types: %w(select_one integer), is_standard: true)

        # Create condition.
        @std.c[1].condition = build(:condition,
          ref_qing: @std.c[0],
          op: 'eq',
          option_node_id: @std.c[0].option_set.c[1].id
        )
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

      # This also tests that OptionNodes can be found using their original_id because:
      # 1. on this copy operation, the OptionSet and OptionNodes are not actually copied, just reused
      # 2. this is because they were copied previously when the question was copied
      # 3. therefore the only way to link the condition correctly is by finding the OptionNode by original_id
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
        expect(@copy.c[1].condition.option_node_id).to eq @copy.c[0].option_set.c[1].id
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

  describe 'destroy' do
    context 'with copies' do
      it 'should be possible' do
        @std = create(:form, is_standard: true)
        @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
        create(:response, form: @copy)

        expect { @std.destroy }.not_to raise_error
        expect { @copy.reload }.not_to raise_error

        expect(@copy.original).to be_nil
        expect(@copy.standard_copy?).to be_falsy
      end
    end
  end

  def form_items_qing_count(form_id)
    FormItem.where(form_id: form_id, type: 'Questioning').count
  end
end
