# frozen_string_literal: true

# There are many more form replication tests in test/unit/standardizable
require "rails_helper"

describe Form do
  let(:mission1) { create(:mission) }

  describe "to_mission" do
    context "with doubly nested questions and repeat groups" do
      let!(:std) do
        create(:form, :standard,
          question_types: ["integer", {repeating: {items: ["select_one", "integer",
                                                           {repeating: {items: %w[text text]}}]}}])
      end
      let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }

      it "produces distinct child objects with correct attribs and form references" do
        # Root group ancestry should be nil, not empty string.
        expect(copy.root_group.ancestry).to be_nil

        expect(copy).not_to eq(std)

        expect(copy.root_group.class).to eq(QingGroup)
        expect(copy.root_group).not_to eq(std.root_group)
        expect(copy.root_group.form).to eq(copy)

        expect(copy.c[0]).not_to eq(std.c[0])
        expect(copy.c[0].qtype_name).to eq("integer")
        expect(copy.c[0].form).to eq(copy)

        expect(copy.c[1]).not_to eq(std.c[1])
        expect(copy.c[1].class).to eq(QingGroup)
        expect(copy.c[1]).to be_repeatable
        expect(copy.c[1].form).to eq(copy)

        expect(copy.c[1].c[0]).not_to eq(std.c[1].c[0])
        expect(copy.c[1].c[0].qtype_name).to eq("select_one")
        expect(copy.c[1].c[0].form).to eq(copy)

        expect(copy.c[1].c[2]).not_to eq(std.c[1].c[2])
        expect(copy.c[1].c[2].class).to eq(QingGroup)
        expect(copy.c[1].c[2]).to be_repeatable
        expect(copy.c[1].c[2].form).to eq(copy)

        expect(copy.c[1].c[2].c[1]).not_to eq(std.c[1].c[2].c[1])
        expect(copy.c[1].c[2].c[1].qtype_name).to eq("text")
        expect(copy.c[1].c[2].c[1].form).to eq(copy)
      end
    end

    context "with an existing copy of form in mission" do
      let!(:std) { create(:form, :standard, question_types: %w[select_one integer]) }
      let!(:copy1) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
      let!(:copy2) { std.replicate(mode: :to_mission, dest_mission: get_mission) }

      it "should create a second copy but re-use questions, option sets" do
        expect(copy1).not_to eq(copy2)
        expect(copy1.c[0]).not_to eq(copy2.c[0])
        expect(copy1.c[0].question).to eq(copy2.c[0].question)
        expect(copy1.c[0].option_set).to eq(copy2.c[0].option_set)
      end

      context "when using eager loaded values from form items query" do
        let(:std_qing_count) { Questioning.where(form: std).count }
        let(:copy1_qing_count) { Questioning.where(form: copy1).count }
        let(:copy2_qing_count) { Questioning.where(form: copy2).count }

        it "keeps the questioning count consistent" do
          expect(std_qing_count).to eq(copy1_qing_count)
          expect(std_qing_count).to eq(copy2_qing_count)
        end
      end
    end

    context "with a condition referencing an option from a multilevel set" do
      let!(:std) { create(:form, :standard, question_types: %w[multilevel_select_one text integer]) }
      let!(:std_conditions) do
        # Two conditions on the last questioning, one referencing the multilevel Q, and one the text Q.
        [std.c[2].display_conditions.create!(left_qing: std.c[0], op: "eq",
                                             option_node_id: std.c[0].option_set.c[1].c[0].id),
         std.c[2].display_conditions.create!(left_qing: std.c[1], op: "eq", value: "foo")]
      end

      context "if all goes well" do
        let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
        let!(:copy_conditions) { copy.c[2].display_conditions.sort_by(&:left_qing_rank) }
        let!(:copy_option_node) { copy.c[0].option_set.c[1].c[0] }

        it "should produce distinct child objects" do
          expect(std.c[2]).not_to eq(copy.c[2])
          expect(copy_conditions.size).to eq(2)
          expect(std_conditions & copy_conditions).to be_empty
          expect(std.c[0].options.min).not_to eq(copy.c[0].option_set.options.min)
          expect(std_conditions[0].option_node).not_to eq(copy_conditions[0].option_node)
          expect(std_conditions[1]).not_to eq(copy_conditions[1])
        end

        it "should produce correct condition-qing link" do
          expect(copy_conditions[0].left_qing).to eq(copy.c[0])
          expect(copy_conditions[1].left_qing).to eq(copy.c[1])
        end

        it "should produce correct new option node reference" do
          expect(copy_conditions[0].option_node_id).to eq(copy_option_node.id)
          expect(copy_conditions[0].option_node.option).to eq(copy_option_node.option)
          expect(copy_conditions[0].option_node.name).to eq("Tulip")
        end
      end

      context "if the option has since been deleted in the mission" do
        let!(:os_copy) do
          # Replicate the option set and delete an option
          std.c[0].option_set.replicate(mode: :to_mission, dest_mission: get_mission).tap do |os_copy|
            os_copy.c[1].c[0].destroy
          end
        end
        let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }

        it "should copy question but not the condition" do
          expect(copy.c[2].code).to eq(std.c[2].code)
          expect(std.c[2].display_conditions[0]).to be_present
          expect(copy.c[2].display_conditions.size).to eq(1)
          expect(copy.c[2].display_conditions[0].left_qing).to eq(copy.c[1])
        end
      end
    end

    context "with an option set already imported to a different mission" do
      let(:mission1) { create(:mission) }
      let(:mission2) { create(:mission) }
      let!(:std) { create(:form, :standard, question_types: %w[select_one integer]) }

      before do
        std.c[1].display_conditions.create!(left_qing: std.c[0], op: "eq",
                                            option_node: std.c[0].option_set.c[0])
        std.replicate(mode: :to_mission, dest_mission: mission1)
      end

      context "with same option set previously copied to mission2" do
        let(:copy2) { std.replicate(mode: :to_mission, dest_mission: mission2) }

        before do
          std.c[0].option_set.replicate(mode: :to_mission, dest_mission: mission2)
        end

        it "should link the condition properly" do
          expect(copy2.c[1].display_conditions.first.option_node.mission).to eq(mission2)
        end
      end
    end

    context "with a condition referencing a now-incompatible question" do
      let(:std) { create(:form, :standard, question_types: %w[select_one integer]) }
      let(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
      let(:question_copy) { std.c[0].question.replicate(mode: :to_mission, dest_mission: mission1) }

      before do
        # Create condition. Standard form gets created here.
        std.c[1].display_conditions.create!(left_qing: std.c[0], op: "eq",
                                            option_node_id: std.c[0].option_set.c[1].id)

        # Render the first question copy incompatible.
        # First copy happens here.
        question_copy.update!(option_set: create(:option_set, mission: mission1))
      end

      # This also tests that OptionNodes can be found using their original_id because:
      # 1. on this copy operation, the OptionSet and OptionNodes are not actually copied, just reused
      # 2. this is because they were copied previously when the question was copied
      # 3. therefore the only way to link the condition correctly is by finding the OptionNode by original_id
      it "should make a new copy of the question and link properly" do
        # Link should get erased when becoming incompatible.
        expect(question_copy.original_id).to be_nil
        expect(question_copy.standard_copy?).to be(false)

        # New question copy should have been created. Form copy happens here.
        expect(copy.c[0].question).not_to eq(question_copy)
        expect(copy.c[0].question.original).to eq(std.c[0].question)
        expect(copy.c[0].question.standard_copy?).to be(true)

        # Condition should point to newer question copy.
        expect(copy.c[1].display_conditions[0].left_qing).to eq(copy.c[0])
        expect(copy.c[1].display_conditions[0].option_node_id).to eq(copy.c[0].option_set.c[1].id)
      end
    end

    context "with skip rules" do
      let(:std) { create(:form, :standard, question_types: %w[integer integer integer integer]) }

      before do
        std.c[1].skip_rules.create!(destination: "item", dest_item: std.c[3], skip_if: "all_met",
                                    conditions_attributes: [
                                      {left_qing_id: std.c[0].id, op: "eq", value: "4"},
                                      {left_qing_id: std.c[1].id, op: "eq", value: "8"}
                                    ])
      end

      context "if all goes well" do
        let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }

        it "should produce distinct child objects with correct references" do
          expect(std.reload.c[1].skip_rules.size).to eq(1)
          expect(copy.c[1].skip_rules.size).to eq(1)
          expect(copy.c[1].skip_rules[0].destination).to eq("item")
          expect(copy.c[1].skip_rules[0].skip_if).to eq("all_met")
          expect(copy.c[1].skip_rules[0].dest_item_id).to eq(copy.c[3].id)
          expect(copy.c[1].skip_rules[0].conditions.size).to eq(2)
          expect(copy.c[1].skip_rules[0].conditions[0].left_qing_id).to eq(copy.c[0].id)
          expect(copy.c[1].skip_rules[0].conditions[0].value).to eq("4")
          expect(copy.c[1].skip_rules[0].conditions[1].left_qing_id).to eq(copy.c[1].id)
          expect(copy.c[1].skip_rules[0].conditions[1].value).to eq("8")
          expect(copy.c[0].id).not_to eq(std.c[0].id)
          expect(copy.c[1].id).not_to eq(std.c[1].id)
        end
      end
    end

    context "with constraints" do
      let(:std) { create(:form, :standard, question_types: %w[integer integer]) }

      before do
        std.c[1].constraints.create!(accept_if: "any_met", rejection_msg_translations: {en: "Foo", fr: "Bar"},
                                     conditions_attributes: [
                                       {left_qing_id: std.c[0].id, op: "lt", value: "4"},
                                       {left_qing_id: std.c[1].id, op: "eq", right_qing_id: std.c[0].id}
                                     ])
      end

      context "if all goes well" do
        let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }

        it "should produce distinct child objects with correct references" do
          expect(std.reload.c[1].constraints.size).to eq(1)
          expect(copy.c[0].constraints.size).to eq(0)
          expect(copy.c[1].constraints.size).to eq(1)
          expect(copy.c[1].constraints[0].accept_if).to eq("any_met")
          expect(copy.c[1].constraints[0].rejection_msg_translations).to eq("en" => "Foo", "fr" => "Bar")
          expect(copy.c[1].constraints[0].conditions.size).to eq(2)
          expect(copy.c[1].constraints[0].conditions[0].left_qing_id).to eq(copy.c[0].id)
          expect(copy.c[1].constraints[0].conditions[0].op).to eq("lt")
          expect(copy.c[1].constraints[0].conditions[0].value).to eq("4")
          expect(copy.c[1].constraints[0].conditions[1].left_qing_id).to eq(copy.c[1].id)
          expect(copy.c[1].constraints[0].conditions[1].op).to eq("eq")
          expect(copy.c[1].constraints[0].conditions[1].right_qing_id).to eq(copy.c[0].id)
          expect(copy.c[0].id).not_to eq(std.c[0].id)
          expect(copy.c[1].id).not_to eq(std.c[1].id)
        end
      end
    end
  end

  describe "clone" do
    context "basic" do
      let(:orig) { create(:form, :standard, question_types: ["integer", %w[select_one integer]]) }
      let(:copy) { orig.replicate(mode: :clone) }

      before do
        orig.reload
      end

      it "should reuse only reusable objects" do
        expect(orig).not_to eq(copy)
        expect(orig.root_group).not_to eq(copy.root_group)
        expect(orig.c[0]).not_to eq(copy.c[0])
        expect(orig.c[0].question).to eq(copy.c[0].question) # Questions reusable
        expect(orig.c[1].c[0]).not_to eq(copy.c[1].c[0]) # Questionings not reusable
        expect(orig.c[1].c[0].option_set).to eq(copy.c[1].c[0].option_set) # OptionSets reusable
        expect(orig.c[1].c[0].option_set.preordered_option_nodes).to eq(
          copy.c[1].c[0].option_set.preordered_option_nodes # OptionNodes reusable
        )
        expect(orig.c[1].c[0].option_set.first_level_options).to eq(
          copy.c[1].c[0].option_set.first_level_options # Options reusable
        )
      end

      it "should produce correct form references" do
        expect(copy.root_group.form).to eq(copy)
        expect(copy.c[0].form).to eq(copy)
        expect(copy.c[1].c[0].form).to eq(copy)
      end

      context "with form attributes" do
        before { orig.update!(default_response_name: "foo") }

        it "should copy default response name" do
          expect(copy.default_response_name).to eq(orig.default_response_name)
        end
      end

      context "with questioning attributes" do
        before do
          orig.c[0].update!(hidden: true, disabled: true, group_item_name_translations: {en: "foo"})
        end

        it "should copy hidden/disabled attributes" do
          expect(copy.c[0].hidden).to eq(true)
          expect(copy.c[0].disabled).to eq(true)
        end

        it "should copy group item name translations" do
          expect(copy.c[0].group_item_name_translations).to eq("en" => "foo")
        end
      end

      context "with live form in mission" do
        let(:orig) { create(:form, :live, question_types: ["integer"]) }

        it "copy should be draft" do
          expect(copy).to be_draft
        end
      end
    end

    context "for multiple clones" do
      let(:f1) { create(:form, name: "Myform") }
      let(:f2) { f1.replicate(mode: :clone) }
      let(:f3) { f2.replicate(mode: :clone) }
      let(:f4) { f3.replicate(mode: :clone) }

      it "should avoid name collisions" do
        expect(f2.name).to eq("Myform 2")
        expect(f3.name).to eq("Myform 3")
        expect(f4.name).to eq("Myform 4")
      end
    end

    context "for a form with symbols in its name" do
      # See models/form.rb for validations; some symbols are completely disallowed.
      let(:orig) { create(:form, name: "The [Form]") }
      let(:copy) { orig.replicate(mode: :clone) }

      it "should work" do
        expect(copy.name).to eq("The [Form] 2")
      end
    end

    context "with a condition referencing an option from a multilevel set" do
      let!(:std) { create(:form, mission: mission1, question_types: %w[multilevel_select_one text]) }
      let!(:std_condition) do
        std.c[1].display_conditions.create!(
          left_qing: std.c[0], op: "eq", option_node_id: std.c[0].option_set.c[1].c[0].id
        )
      end

      context "if all goes well" do
        let!(:copy) { std.replicate(mode: :clone) }
        let!(:copy_condition) { copy.c[1].display_conditions[0] }
        let!(:copy_option_node) { copy.c[0].option_set.c[1].c[0] }

        it "should produce distinct child objects" do
          expect(std.c[1]).not_to eq(copy.c[1])
          expect(std_condition).not_to eq(copy_condition)
          # These two should be equal because they're referencing the same option set.
          expect(std.c[0].options.min).to eq(copy.c[0].option_set.options.min)
          expect(std.c[1].display_conditions[0].option_node).to eq(copy_condition.option_node)
        end

        it "should produce correct condition-qing link" do
          expect(copy_condition.left_qing).to eq(copy.c[0])
        end

        it "should produce correct new option node reference" do
          expect(copy_condition.option_node_id).to eq(copy_option_node.id)
          expect(copy_condition.option_node.option).to eq(copy_option_node.option)
          expect(copy_condition.option_node.name).to eq("Tulip")
        end
      end
    end
  end

  describe "destroy" do
    context "with copies" do
      let!(:std) { create(:form, :standard) }
      let!(:copy) { std.replicate(mode: :to_mission, dest_mission: get_mission) }
      let!(:response) { create(:response, form: copy) }

      it "should be possible" do
        expect { std.destroy }.not_to raise_error
        expect { copy.reload }.not_to raise_error
        expect(copy.original).to be_nil
        expect(copy.standard_copy?).to be_falsy
      end
    end
  end
end
