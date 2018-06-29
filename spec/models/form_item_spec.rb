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
        expect(form.c.map(&:rank)).to eq [1, 2, 3, 4, 5]
      end

      it "should ignore deleted items when adding rank" do
        form.c[4].destroy
        qing = create(:questioning, form: form, parent: form.root_group)
        expect(qing.rank).to eq 5
      end

      it "should adjust ranks when existing questioning moved to the empty group" do
        old1, old2, old3, old4 = form.c
        old2.move(group, 1)
        expect(old1.reload.rank).to eq 1
        expect(old2.reload.rank).to eq 1
        expect(old3.reload.rank).to eq 2 # Should move down one.
        expect(old4.reload.rank).to eq 3 # Should move down one.
      end

      it "should change order of the questioning moved higher" do
        child2 = form.c[2]
        child3 = form.c[3]
        child3.move_higher
        expect(child2.reload.rank).to eq 4
        expect(child3.reload.rank).to eq 3
      end

      it "should change order of the questioning moved lower" do
        child0 = form.c[0]
        child1 = form.c[1]
        child0.move_lower
        expect(child0.reload.rank).to eq 2
        expect(child1.reload.rank).to eq 1
      end

      it "should fix ranks when item deleted" do
        (q = form.c[1]).destroy
        expect(form.c).not_to include q
        expect(form.c.map(&:rank)).to eq [1, 2, 3, 4]
      end
    end

    context "with nested form" do
      let(:form) { create(:form, question_types: ["text", ["text", "text"]]) }

      it "should work when changing ranks of second level items" do
        q1, q2 = form.c[1].c
        q2.move(q2.parent, 1)
        expect(q1.reload.rank).to eq 2
        expect(q2.reload.rank).to eq 1
      end

      it "should ignore deleted children when moving item to group" do
        form.c[1].c[1].destroy
        form.c[0].move(form.c[1], 2)
        expect(form.reload.c[0].c.map(&:rank)).to eq [1, 2]
      end

      it "should trim requested rank when moving if too low" do
        old1 = form.c[0]
        form.c[0].move(form.c[1], 0)
        expect(form.reload.c[0].c.map(&:rank)).to eq [1, 2, 3]
        expect(old1.reload.rank).to eq 1
      end

      it "should trim requested rank when moving if too high" do
        old1 = form.c[0]
        form.c[0].move(form.c[1], 10)
        expect(form.reload.c[0].c.map(&:rank)).to eq [1, 2, 3]
        expect(old1.reload.rank).to eq 3
      end
    end
  end

  describe "tree traversal" do
    context "with deeply nested form" do
      let(:form) { create(:form, question_types: ["text", ["text", "text"], ["text", "text", ["text", "text"]]]) }
      let(:qing) { form.c[2].c[0] }
      let(:other_qing) { form.c[2].c[2].c[0] }
      let(:common_ancestor) { form.c[2] }

      it "should be able to find its lowest common ancestor with another node" do
        expect(qing.lowest_common_ancestor(other_qing).id).to eq common_ancestor.id
      end
    end
  end

  describe "normalization" do
    let(:form_item) { create(:qing_group, submitted.merge(display_conditions_attributes: cond_attrs)) }
    let(:ref_qing) { create(:questioning) }
    subject { submitted.keys.map { |k| [k, form_item.send(k)] }.to_h }

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
        let(:cond_attrs) { [{ref_qing_id: "", op: "", value: "  "}] }

        context do
          let(:submitted) { {display_if: "all_met"} }
          it { is_expected.to eq(display_if: "always") }

          it "should discard condition" do
            expect(form_item.display_conditions).to be_empty
          end
        end
      end

      context "with partial condition" do
        let(:cond_attrs) { [{ref_qing_id: ref_qing.id, op: "", value: "  "}] }
        let(:submitted) { {display_if: "all_met"} }

        it "should fail validation" do
          expect { form_item }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "with full condition" do
        let(:cond_attrs) { [{ref_qing_id: ref_qing.id, op: "eq", value: "foo"}] }

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
          {destination: "", skip_if: "", conditions_attributes: [{ref_qing_id: "", op: "", value: ""}]}
        ])
      end

      it "should be discarded if totally empty" do
        expect(qing.skip_rules.count).to eq 1
        expect(qing.skip_rules[0].destination).to eq "end"
      end
    end
  end

  describe "#refable_qings" do
    let(:form) { create(:form, question_types:
      ["text", "location", "text", ["text", %w(text text text), "text"], "text", "text"]) }

    it "is correct for subsubquestion" do
      expect(form.c[3].c[1].c[1].refable_qings).to eq [
        form.c[0],
        form.c[2],
        form.c[3].c[0],
        form.c[3].c[1].c[0],
        form.c[3].c[1].c[1]
      ]
    end

    it "is correct for subgroup" do
      expect(form.c[3].c[1].refable_qings).to eq [
        form.c[0],
        form.c[2],
        form.c[3].c[0]
      ]
    end

    it "is correct for first question on form" do
      expect(form.c[0].refable_qings).to eq [form.c[0]]
    end

    it "returns all questionings of refable type on form if host item not persisted" do
      # Expect everything except groups and location question.
      expect(FormItem.new(form: form).refable_qings).to eq(
        (form.preordered_items - [form.c[1], form.c[3], form.c[3].c[1]]))
    end
  end

  describe "#later_items" do
    let(:form) { create(:form, question_types:
      ["text", "text", ["text", %w(text text text), "text"], "text", "text"]) }

    it "is correct for subsubquestion" do
      expect(form.c[2].c[1].c[1].later_items).to eq [
        form.c[2].c[1].c[2],
        form.c[2].c[2],
        form.c[3],
        form.c[4]
      ]
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
      expect(item).to receive(:form).and_return(form = double())
      expect(form).to receive(:preordered_items).with(eager_load: %i[form question]).and_return([item])
      item.later_items(eager_load: :form)
    end
  end
end
