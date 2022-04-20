# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: form_items
#
#  id                           :uuid             not null, primary key
#  all_levels_required          :boolean          default(FALSE), not null
#  ancestry                     :text
#  ancestry_depth               :integer          not null
#  default                      :string
#  disabled                     :boolean          default(FALSE), not null
#  display_if                   :string           default("always"), not null
#  group_hint_translations      :jsonb
#  group_item_name_translations :jsonb
#  group_name_translations      :jsonb
#  hidden                       :boolean          default(FALSE), not null
#  one_screen                   :boolean
#  preload_last_saved           :boolean          default(FALSE), not null
#  rank                         :integer          not null
#  read_only                    :boolean
#  repeatable                   :boolean
#  required                     :boolean          default(FALSE), not null
#  type                         :string(255)      not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  form_id                      :uuid             not null
#  form_old_id                  :integer
#  mission_id                   :uuid
#  old_id                       :integer
#  question_id                  :uuid
#  question_old_id              :integer
#
# Indexes
#
#  index_form_items_on_ancestry                 (ancestry)
#  index_form_items_on_form_id                  (form_id)
#  index_form_items_on_form_id_and_question_id  (form_id,question_id) UNIQUE
#  index_form_items_on_mission_id               (mission_id)
#  index_form_items_on_question_id              (question_id)
#
# Foreign Keys
#
#  form_items_form_id_fkey      (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  form_items_mission_id_fkey   (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  form_items_question_id_fkey  (question_id => questions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe FormItem do
  describe "parent must be group" do
    let(:form) { create(:form, question_types: ["text", %w[text text]]) }
    let(:qing) { form.c[0] }
    let(:qing2) { form.c[1].c[0] }
    let(:qing_group) { form.c[1] }

    it "should save cleanly if parent is group" do
      qing.parent = qing_group
      qing.save
    end

    it "should raise error if attempting to set questioning as parent of questioning" do
      qing2.parent = qing
      expect { qing2.save }.to raise_error(ParentMustBeGroupError)
    end

    it "should raise error if attempting to set questioning as parent of group" do
      qing_group.parent = qing
      expect { qing_group.save }.to raise_error(ParentMustBeGroupError)
    end
  end

  describe "ranks" do
    context "with flat form" do
      let!(:form) { create(:form, question_types: %w[text text text text]) }
      let!(:group) { create(:qing_group, form: form, parent: form.root_group) }

      it "should create 4 questionings and one group with correct ranks" do
        expect(form.c.map(&:rank)).to eq([1, 2, 3, 4, 5])
      end

      it "should ignore deleted items when adding rank" do
        form.c[4].destroy
        qing = create(:questioning, form: form, parent: form.root_group)
        expect(qing.rank).to eq(5)
      end

      it "should adjust ranks when existing questioning moved to the empty group" do
        old1, old2, old3, old4 = form.c
        old2.move(group, 1)
        expect(old1.reload.rank).to eq(1)
        expect(old2.reload.rank).to eq(1)
        expect(old3.reload.rank).to eq(2) # Should move down one.
        expect(old4.reload.rank).to eq(3) # Should move down one.
      end

      it "should change order of the questioning moved higher" do
        child2 = form.c[2]
        child3 = form.c[3]
        child3.move_higher
        expect(child2.reload.rank).to eq(4)
        expect(child3.reload.rank).to eq(3)
      end

      it "should change order of the questioning moved lower" do
        child0 = form.c[0]
        child1 = form.c[1]
        child0.move_lower
        expect(child0.reload.rank).to eq(2)
        expect(child1.reload.rank).to eq(1)
      end

      it "should fix ranks when item deleted" do
        (q = form.c[1]).destroy
        expect(form.c).not_to include(q)
        expect(form.c.map(&:rank)).to eq([1, 2, 3, 4])
      end
    end

    context "with nested form" do
      let(:form) { create(:form, question_types: ["text", %w[text text]]) }

      it "should work when changing ranks of second level items" do
        q1, q2 = form.c[1].c
        q2.move(q2.parent, 1)
        expect(q1.reload.rank).to eq(2)
        expect(q2.reload.rank).to eq(1)
      end

      it "should ignore deleted children when moving item to group" do
        form.c[1].c[1].destroy
        form.c[0].move(form.c[1], 2)
        expect(form.reload.c[0].c.map(&:rank)).to eq([1, 2])
      end

      it "should trim requested rank when moving if too low" do
        old1 = form.c[0]
        form.c[0].move(form.c[1], 0)
        expect(form.reload.c[0].c.map(&:rank)).to eq([1, 2, 3])
        expect(old1.reload.rank).to eq(1)
      end

      it "should trim requested rank when moving if too high" do
        old1 = form.c[0]
        form.c[0].move(form.c[1], 10)
        expect(form.reload.c[0].c.map(&:rank)).to eq([1, 2, 3])
        expect(old1.reload.rank).to eq(3)
      end
    end
  end

  describe "tree traversal" do
    context "with deeply nested form" do
      let(:form) { create(:form, question_types: ["text", %w[text text], ["text", "text", %w[text text]]]) }
      let(:qing) { form.c[2].c[0] }
      let(:other_qing) { form.c[2].c[2].c[0] }
      let(:common_ancestor) { form.c[2] }

      it "should be able to find its lowest common ancestor with another node" do
        expect(qing.lowest_common_ancestor(other_qing).id).to eq(common_ancestor.id)
      end
    end
  end

  describe "normalization" do
    let(:form_item) { create(:qing_group, submitted.merge(display_conditions_attributes: cond_attrs)) }
    let(:left_qing) { create(:questioning) }
    subject { submitted.keys.index_with { |k| form_item.send(k) }.to_h }

    describe "display_conditions and display_if" do
      context "with no conditions" do
        let(:cond_attrs) { [] }

        context do
          let(:submitted) { {display_if: "all_met"} }
          it { is_expected.to eq(display_if: "always") }
        end

        context do
          let(:submitted) { {display_if: "any_met"} }
          it { is_expected.to eq(display_if: "always") }
        end

        context do
          let(:submitted) { {display_if: "always"} }
          it { is_expected.to eq(display_if: "always") }
        end
      end

      context "with blank condition" do
        let(:cond_attrs) { [{left_qing_id: "", op: "", value: "  "}] }

        context do
          let(:submitted) { {display_if: "all_met"} }
          it { is_expected.to eq(display_if: "always") }

          it "should discard condition" do
            expect(form_item.display_conditions).to be_empty
          end
        end
      end

      context "with partial condition" do
        let(:cond_attrs) { [{left_qing_id: left_qing.id, op: "", value: "  "}] }
        let(:submitted) { {display_if: "all_met"} }

        it "should fail validation" do
          expect { form_item }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "with full condition" do
        let(:cond_attrs) { [{left_qing_id: left_qing.id, op: "eq", value: "foo"}] }

        context do
          let(:submitted) { {display_if: "all_met"} }
          it { is_expected.to eq(display_if: "all_met") }
        end

        context do
          let(:submitted) { {display_if: "any_met"} }
          it { is_expected.to eq(display_if: "any_met") }
        end

        context do
          let(:submitted) { {display_if: "always"} }
          it { is_expected.to eq(display_if: "all_met") }
        end
      end
    end

    describe "skip_rules" do
      let(:qing) do
        create(:questioning, skip_rules_attributes: [
          {destination: "end", skip_if: "always"},
          {destination: "", skip_if: "", conditions_attributes: []},
          {destination: "", skip_if: "", conditions_attributes: [{left_qing_id: "", op: "", value: ""}]}
        ])
      end

      it "should be discarded if totally empty" do
        expect(qing.skip_rules.count).to eq(1)
        expect(qing.skip_rules[0].destination).to eq("end")
      end
    end
  end

  describe "#refable_qings" do
    let(:form) do
      create(:form, question_types:
      ["text", "location", "text", ["text", %w[text text text], "text"], "text", "text"])
    end

    it "is correct for subsubquestion" do
      expect(form.c[3].c[1].c[1].refable_qings).to eq([
        form.c[0],
        form.c[2],
        form.c[3].c[0],
        form.c[3].c[1].c[0],
        form.c[3].c[1].c[1]
      ])
    end

    it "is correct for subgroup" do
      expect(form.c[3].c[1].refable_qings).to eq([
        form.c[0],
        form.c[2],
        form.c[3].c[0]
      ])
    end

    it "is correct for first question on form" do
      expect(form.c[0].refable_qings).to eq([form.c[0]])
    end

    it "returns all questionings of refable type on form if host item not persisted" do
      # Expect everything except groups and location question.
      expect(FormItem.new(form: form).refable_qings).to eq(
        (form.preordered_items - [form.c[1], form.c[3], form.c[3].c[1]])
      )
    end
  end

  describe "#later_items" do
    let(:form) do
      create(:form, question_types:
      ["text", "text", ["text", %w[text text text], "text"], "text", "text"])
    end

    it "is correct for subsubquestion" do
      expect(form.c[2].c[1].c[1].later_items).to eq([
        form.c[2].c[1].c[2],
        form.c[2].c[2],
        form.c[3],
        form.c[4]
      ])
    end

    it "is correct for first question" do
      expect(form.c[0].later_items).to eq(form.root_group.preordered_descendants - [form.c[0]])
    end

    it "is correct for last question" do
      expect(form.c[4].later_items).to be_empty
    end

    it "returns empty array if host item not persisted" do
      expect(FormItem.new(form: form).later_items).to be_empty
    end

    it "passes along eager_load" do
      item = form.c[0]
      expect(item).to receive(:form).and_return(form = double)
      expect(form).to receive(:preordered_items).with(eager_load: %i[form question]).and_return([item])
      item.later_items(eager_load: :form)
    end
  end

  describe "destroy" do
    context "with display conditions" do
      let!(:form) { create(:form, question_types: %w[text text text]) }
      let!(:condition) do
        form.c[1].display_conditions.create!(left_qing: form.c[0], op: "eq", value: "foo")
      end

      it "should destroy cleanly" do
        form.c[1].destroy
        expect(Condition.count).to be_zero
      end
    end

    context "with referring conditions (via both left_qing and right_qing)" do
      let!(:form) { create(:form, question_types: %w[text text text]) }
      let!(:left_condition) do
        form.c[1].display_conditions.create!(left_qing: form.c[0], op: "eq", value: "foo")
      end
      let!(:right_condition) do
        form.c[2].display_conditions.create!(left_qing: form.c[1], op: "eq", right_side_type: "qing",
                                             right_qing: form.c[0])
      end

      it "should destroy cleanly" do
        form.c[0].destroy
        expect(Condition.count).to be_zero
      end
    end

    context "with incoming and outgoing skip rules" do
      let!(:form) { create(:form, question_types: %w[text text text]) }
      let!(:skip_rule1) do
        form.c[0].skip_rules.create!(destination: "item", dest_item: form.c[1], skip_if: "always")
      end
      let!(:skip_rule2) do
        form.c[1].skip_rules.create!(destination: "item", dest_item: form.c[2], skip_if: "always")
      end

      it "should destroy cleanly" do
        form.c[1].destroy
        expect(SkipRule.count).to be_zero
      end
    end

    context "with constraints" do
      let!(:form) { create(:form, question_types: %w[text text text]) }
      let!(:constraint) do
        form.c[1].constraints.create!(conditions_attributes: [{left_qing: form.c[1], op: "eq", value: "foo"}])
      end

      it "should destroy cleanly" do
        form.c[1].destroy
        expect(Constraint.count).to be_zero
      end
    end
  end
end
