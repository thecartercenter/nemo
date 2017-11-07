require "spec_helper"

describe FormItem do
  before do
    @user = create(:user, role_name: "coordinator")
    @form = create(:form, question_types: ["text", ["text", "text"]])
    @qing = @form.c[0]
    @qing_group = @form.c[1]
  end

  describe "parent validation" do
    it "should raise error if attempting to set questioning as parent of questioning" do
      @qing2 = @form.c[1].c[0]
      @qing2.parent = @qing
      @qing2.save
      expect(@qing2.errors.messages.values.flatten).to include "Parent must be a group."
    end

    it "should raise error if attempting to set questioning as parent of group" do
      @qing_group.parent = @qing
      @qing_group.save
      expect(@qing_group.errors.messages.values.flatten).to include "Parent must be a group."
    end
  end

  describe "ranks" do
    context "with flat form" do
      let!(:form) { create(:form, question_types: %w(text text text text)) }
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
  end
end
