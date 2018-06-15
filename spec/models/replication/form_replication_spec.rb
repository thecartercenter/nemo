# There are many more form replication tests in test/unit/standardizable
require "rails_helper"

describe Form do
  let(:mission1) { create(:mission) }

  describe "to_mission" do
    context "with nested questions" do
      let!(:std) { create(:form, question_types: ["integer", %w(select_one integer)], is_standard: true) }
      let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
      let(:std_group) { std.children.detect { |c| c.is_a? QingGroup } }
      let(:copy_group) { copy.children.detect { |c| c.is_a? QingGroup } }
      let(:std_group_select) { std_group.children.detect { |c| c.qtype_name == "select_one" } }
      let(:copy_group_select) { copy_group.children.detect { |c| c.qtype_name == "select_one" } }

      it "should not produce blank ancestry (only nil)" do
        expect(copy.root_group.ancestry).to be_nil
      end

      it "should produce distinct child objects" do
        expect(std).not_to eq copy
        expect(std.root_group).not_to eq copy.root_group
        expect(std_group).not_to eq copy_group
        expect(std_group_select).not_to eq copy_group_select
      end

      it "should produce correct form references" do
        expect(copy.root_group.form).to eq copy
        expect(copy.sorted_children.first.form).to eq copy
        expect(copy_group_select.form).to eq copy
      end
    end

    context "with an existing copy of form in mission" do
      let!(:std) { create(:form, question_types: %w(select_one integer), is_standard: true) }
      let!(:copy1) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
      let!(:copy2) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
      let(:copy1_select) { copy1.children.detect { |c| c.qtype_name == "select_one" } }
      let(:copy2_select) { copy2.children.detect { |c| c.qtype_name == "select_one" } }

      it "should create a second copy but re-use questions, option sets" do
        expect(copy1).not_to eq copy2
        expect(copy1_select).not_to eq copy2_select
        expect(copy1_select.question).to eq copy2_select.question
        expect(copy1_select.question.option_set).to eq copy2_select.question.option_set
      end

      context "when using eager loaded values from form items query" do
        it "keeps the questioning count consistent" do
          std_qing_count = form_items_qing_count(std)
          copy1_qing_count = form_items_qing_count(copy1)
          copy2_qing_count = form_items_qing_count(copy2)

          expect(std_qing_count).to eq copy1_qing_count
          expect(std_qing_count).to eq copy2_qing_count
        end
      end
    end

    context "with a condition referencing an option from a multilevel set" do
      let!(:std) { create(:form, is_standard: true) }
      let!(:std_questionings) do
        {
          multilevel: create_questioning("multilevel_select_one", std),
          text: create_questioning("text", std),
          integer: create_questioning("integer", std)
        }
      end
      let!(:std_option_node) do
        std_questionings[:multilevel].option_set.children.
          detect { |c| c.option_name == "Plant" }.children.
          detect { |c| c.option_name == "Tulip" }
      end
      let!(:std_conditions) do [
        # Two conditions on the last questioning, one referencing the multilevel Q, and one the text Q.
        std_questionings[:integer].display_conditions.create!(
          ref_qing: std_questionings[:multilevel], op: "eq", option_node_id: std_option_node.id),
        std_questionings[:integer].display_conditions.create!(
          ref_qing: std_questionings[:text], op: "eq", value: "foo")
      ] end
      let(:copy_questionings) do
        {
          multilevel: copy.children.detect { |c| c.qtype_name == "select_one" },
          text: copy.children.detect { |c| c.qtype_name == "text" },
          integer: copy.children.detect { |c| c.qtype_name == "integer" }
        }
      end

      context "if all goes well" do
        let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
        let!(:copy_conditions) { copy_questionings[:integer].display_conditions.sort_by(&:ref_qing_rank) }
        let!(:copy_opt_set) { copy_questionings[:multilevel].option_set }
        let!(:copy_option_node) do
          copy_questionings[:multilevel].option_set.children.
            detect { |c| c.option_name == "Plant" }.children.
            detect { |c| c.option_name == "Tulip" }
        end

        it "should produce distinct child objects" do
          expect(std_questionings[:integer]).not_to eq copy_questionings[:integer]
          expect(copy_conditions.size).to eq 2
          expect(std_conditions & copy_conditions).to be_empty
          expect(std_questionings[:multilevel].options.sort[0]).not_to eq copy_opt_set.options.sort[0]
          expect(std_conditions[0].option_node).not_to eq copy_conditions[0].option_node
          expect(std_conditions[1]).not_to eq copy_conditions[1]
        end

        it "should produce correct condition-qing link" do
          expect(copy_conditions[0].ref_qing).to eq copy_questionings[:multilevel]
          expect(copy_conditions[1].ref_qing).to eq copy_questionings[:text]
        end

        it "should produce correct new option node reference" do
          expect(copy_conditions[0].option_node_id).to eq(copy_option_node.id)
          expect(copy_conditions[0].option_node.option).to eq(copy_option_node.option)
          expect(copy_conditions[0].option_node.option_name).to eq "Tulip"
        end
      end

      context "if the option has since been deleted in the mission" do
        let!(:option_set_copy) do
          # replicate the option set
          os_copy = std_questionings[:multilevel].option_set.
            replicate(mode: :to_mission, dest_mission: get_mission)
          os_copy.children.
            detect { |c| c.option_name == "Plant" }.children.
            detect { |c| c.option_name == "Tulip" }.destroy
          os_copy
        end
        let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }

        it "should succeed but not copy the condition" do
          # Question should still be copied but copy should not have a condition
          expect(copy_questionings[:integer].code).to eq std_questionings[:integer].code
          expect(std_questionings[:integer].display_conditions[0]).to be_present
          expect(copy_questionings[:integer].display_conditions.size).to eq 1
          expect(copy_questionings[:integer].display_conditions[0].ref_qing).to eq copy_questionings[:text]
        end
      end
    end

    context "with an option set already imported to a different mission" do
      let(:mission1) { create(:mission) }
      let(:mission2) { create(:mission) }
      let!(:std) { create(:form, is_standard: true, question_types: %w(select_one integer)) }

      before do
        std.c[1].display_conditions.create!(ref_qing: std.c[0], op: "eq",
          option_node: std.c[0].option_set.c[0])
        std.replicate(mode: :to_mission, dest_mission: mission1)
      end

      context "with same option set previously copied to mission2" do
        before do
          std.c[0].option_set.replicate(mode: :to_mission, dest_mission: mission2)
        end

        it "should link the condition properly" do
          copy2 = std.replicate(mode: :to_mission, dest_mission: mission2)
          expect(copy2.c[1].display_conditions.first.option_node.mission).to eq mission2
        end
      end
    end

    context "with a condition referencing a now-incompatible question" do
      let!(:std) { create(:form, is_standard: true) }

      before do
        @std = create(:form, question_types: %w(select_one integer), is_standard: true)

        # Create condition.
        @std.c[1].display_conditions.create!(
          ref_qing: @std.c[0],
          op: "eq",
          option_node_id: @std.c[0].option_set.c[1].id
        )

        # Replicate question first and render the copy incompatible.
        @orig_q1 = @std.c[0].question
        @copy_q1 = @orig_q1.replicate(mode: :to_mission, dest_mission: mission1)
        @copy_q1.option_set = create(:option_set, mission: mission1)
        @copy_q1.save!

        # Replicate form.
        @copy = @std.replicate(mode: :to_mission, dest_mission: get_mission)
        @copy_q1.reload
      end

      # This also tests that OptionNodes can be found using their original_id because:
      # 1. on this copy operation, the OptionSet and OptionNodes are not actually copied, just reused
      # 2. this is because they were copied previously when the question was copied
      # 3. therefore the only way to link the condition correctly is by finding the OptionNode by original_id
      it "should make a new copy of the question and link properly" do
        # Link should get erased when becoming incompatible.
        expect(@copy_q1.original_id).to be_nil
        expect(@copy_q1.standard_copy?).to be false

        # New question copy should have been created.
        expect(@copy.c[0].question).not_to eq @copy_q1
        expect(@copy.c[0].question.original).to eq @std.c[0].question
        expect(@copy.c[0].question.standard_copy?).to be true

        # Condition should point to newer question copy.
        expect(@copy.c[1].display_conditions[0].ref_qing).to eq @copy.c[0]
        expect(@copy.c[1].display_conditions[0].option_node_id).to eq @copy.c[0].option_set.c[1].id
      end
    end

    context "with skip rules" do
      let(:std) { create(:form, is_standard: true, question_types: %w(integer integer integer integer)) }

      before do
        std.c[1].skip_rules.create!(destination: "item", dest_item: std.c[3], skip_if: "all_met",
          conditions_attributes: [
            {ref_qing_id: std.c[0].id, op: "eq", value: "4"},
            {ref_qing_id: std.c[1].id, op: "eq", value: "8"}
        ])
      end

      context "if all goes well" do
        let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }

        it "should produce distinct child objects with correct references" do
          expect(std.reload.c[1].skip_rules.size).to eq 1
          expect(copy.c[1].skip_rules.size).to eq 1
          expect(copy.c[1].skip_rules[0].destination).to eq "item"
          expect(copy.c[1].skip_rules[0].skip_if).to eq "all_met"
          expect(copy.c[1].skip_rules[0].dest_item_id).to eq copy.c[3].id
          expect(copy.c[1].skip_rules[0].conditions.size).to eq 2
          expect(copy.c[1].skip_rules[0].conditions[0].ref_qing_id).to eq copy.c[0].id
          expect(copy.c[1].skip_rules[0].conditions[0].value).to eq "4"
          expect(copy.c[1].skip_rules[0].conditions[1].ref_qing_id).to eq copy.c[1].id
          expect(copy.c[1].skip_rules[0].conditions[1].value).to eq "8"
          expect(copy.c[0].id).not_to eq std.c[0].id
          expect(copy.c[1].id).not_to eq std.c[1].id
        end
      end
    end
  end

  describe "clone" do
    context "basic" do
      before do
        @orig = create(:form, question_types: ["integer", %w(select_one integer)], is_standard: true)
        @copy = @orig.replicate(mode: :clone)
        @copy.reload
      end

      it "should reuse only standardizable objects", :implicit_ordering do
        expect(@orig).not_to eq @copy
        expect(@orig.root_group).not_to eq @copy.root_group
        expect(@orig.c[0]).not_to eq @copy.c[0]
        expect(@orig.c[0].question).to eq @copy.c[0].question # Standardizable
        expect(@orig.c[1].c[0]).not_to eq @copy.c[1].c[0]
      end

      it "should produce correct form references", :implicit_ordering do
        expect(@copy.root_group.form).to eq @copy
        expect(@copy.c[0].form).to eq @copy
        expect(@copy.c[1].c[0].form).to eq @copy
      end
    end

    context "for multiple clones" do
      before do
        @f1 = create(:form, name: "Myform")
        @f2 = @f1.replicate(mode: :clone)
        @f3 = @f2.replicate(mode: :clone)
        @f4 = @f3.replicate(mode: :clone)
      end

      it "should avoid name collisions" do
        expect(@f2.name).to eq "Myform 2"
        expect(@f3.name).to eq "Myform 3"
        expect(@f4.name).to eq "Myform 4"
      end
    end

    context "for a form with a parenth in its name" do
      before do
        @orig = create(:form, name: "The (Form)")
        @copy = @orig.replicate(mode: :clone)
      end

      it "should work" do
        expect(@copy.name).to eq "The (Form) 2"
      end
    end

    context "with a condition referencing an option from a multilevel set" do
      let!(:std) { create(:form, mission: mission1) }
      let!(:std_questionings) do
        {
          multilevel: create_questioning("multilevel_select_one", std),
          integer: create_questioning("integer", std)
        }
      end
      let!(:std_option_node) do
        std_questionings[:multilevel].option_set.children.
          detect { |c| c.option_name == "Plant" }.children.
          detect { |c| c.option_name == "Tulip" }
      end
      let!(:std_condition) do
        std_questionings[:integer].display_conditions.create!(
          ref_qing: std_questionings[:multilevel], op: "eq", option_node_id: std_option_node.id)
      end
      let(:copy_questionings) do
        {
          multilevel: copy.children.detect { |c| c.qtype_name == "select_one" },
          integer: copy.children.detect { |c| c.qtype_name == "integer" }
        }
      end

      context "if all goes well" do
        let!(:copy) { std.replicate(mode: :clone) }
        let!(:copy_condition) { copy_questionings[:integer].display_conditions[0] }
        let!(:copy_opt_set) { copy_questionings[:multilevel].option_set }
        let!(:copy_option_node) do
          copy_questionings[:multilevel].option_set.children.
            detect { |c| c.option_name == "Plant" }.children.
            detect { |c| c.option_name == "Tulip" }
        end

        it "should produce distinct child objects" do
          expect(std_questionings[:integer]).not_to eq copy_questionings[:integer]
          expect(std_condition).not_to eq copy_condition

          # These two should be equal because they're referencing the same option set.
          expect(std_questionings[:multilevel].options.sort[0]).to eq copy_opt_set.options.sort[0]
          expect(std_questionings[:integer].display_conditions[0].option_node).
            to eq copy_condition.option_node
        end

        it "should produce correct condition-qing link" do
          expect(copy_condition.ref_qing).to eq copy_questionings[:multilevel]
        end

        it "should produce correct new option node reference" do
          expect(copy_condition.option_node_id).to eq(copy_option_node.id)
          expect(copy_condition.option_node.option).to eq(copy_option_node.option)
          expect(copy_condition.option_node.option_name).to eq "Tulip"
        end
      end
    end
  end

  describe "destroy" do
    context "with copies" do
      it "should be possible" do
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
    FormItem.where(form_id: form_id, type: "Questioning").count
  end
end
