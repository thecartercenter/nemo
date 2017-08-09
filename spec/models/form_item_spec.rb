require "spec_helper"

describe FormItem do
  before do
    @user = create(:user, role_name: 'coordinator')
    @form = create(:form, question_types: ['text', ['text', 'text']])
    @qing = @form.sorted_children[0]
    @qing_group = @form.sorted_children[1]
  end

  describe "parent validation" do
    it "should raise error if attempting to set questioning as parent of questioning" do
      @qing2 = @form.sorted_children[1].sorted_children[0]
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

  describe "sort" do
    context "with flat form" do
      before(:each) do
        @f = create(:form, question_types: ['text', 'text', 'text', 'text'])
        @group = create(:qing_group, form: @f, parent: @f.root_group)
      end

      it 'should create 4 questionings and one group with correct ranks' do
        expect(@f.sorted_children.size).to eq(5)
        expect(@f.sorted_children[0].rank).to be < @f.sorted_children[1].rank
        expect(@f.sorted_children[1].rank).to be < @f.sorted_children[2].rank
        expect(@f.sorted_children[2].rank).to be < @f.sorted_children[3].rank
      end

      it 'should assign a rank to a newly created group' do
        expect(@f.sorted_children[3].rank).to be < @group.rank
      end

      it 'should adjust ranks when existing questioning moved to the empty group' do
        @old_rank_2 = @f.sorted_children[1]
        @old_rank_3 = @f.sorted_children[2]
        @old_rank_4 = @f.sorted_children[3]
        @old_rank_2.parent = @group;
        @old_rank_2.save
        expect(@old_rank_2.reload.rank).to eq 1
        expect(@old_rank_3.reload.rank).to eq 2 # Should move up one.
        expect(@old_rank_4.reload.rank).to eq 3 # Should move up one.
      end

      it 'should change order of the questioning moved higher' do
        child2 = @f.sorted_children[2]
        child3 = @f.sorted_children[3]
        child3.move_higher
        expect(child2.reload.rank).to eq 4
        expect(child3.reload.rank).to eq 3
      end

      it 'should change order of the questioning moved lower' do
        child0 = @f.sorted_children[0]
        child1 = @f.sorted_children[1]
        child0.move_lower
        expect(child0.reload.rank).to eq 2
        expect(child1.reload.rank).to eq 1
      end
    end

    context "with nested form" do
      before do
        @f = create(:form, question_types: ['text', ['text', 'text']])
      end

      it 'should work when changing ranks of second level items' do
        @q1, @q2 = @f.sorted_children[1].sorted_children
        @q2.update_attributes!(rank: 1)
        expect(@q1.reload.rank).to eq 2
        expect(@q2.reload.rank).to eq 1
      end
    end

  end

  describe "tree traversal" do
    context "with deeply nested form" do
      let(:form) { create(:form, question_types: ["text", ["text", "text"], ["text", "text", ["text", "text"]]]) }
      let(:qing) { form.sorted_children[2].sorted_children[0] }
      let(:other_qing) { form.sorted_children[2].sorted_children[2].sorted_children[0] }
      let(:common_ancestor) { form.sorted_children[2] }

      it "should be able to find its lowest common ancestor with another node" do
        expect(qing.lowest_common_ancestor(other_qing).id).to eq common_ancestor.id
      end
    end
  end
end
