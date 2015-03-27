require "spec_helper"

describe FormItem do
  before do
    @user = create(:user, role_name: 'coordinator')
    @form = create(:form, question_types: ['text', ['text', 'text']])
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

  describe "sort" do
    context "with flat form" do
      before(:each) do
        @f = create(:form, question_types: ['text', 'text', 'text', 'text'])
        @group = create(:qing_group, form: @f, parent: @f.root_group)
      end

      it 'should create 4 questionings and one group with correct ranks' do
        expect(@f.c.size).to eq(5)
        expect(@f.c[0].rank).to be < @f.c[1].rank
        expect(@f.c[1].rank).to be < @f.c[2].rank
        expect(@f.c[2].rank).to be < @f.c[3].rank
      end

      it 'should assign a rank to a newly created group' do
        expect(@f.c[3].rank).to be < @group.rank
      end

      it 'should adjust ranks when existing questioning moved to the empty group' do
        @old_rank_2 = @f.c[1]
        @old_rank_3 = @f.c[2]
        @old_rank_4 = @f.c[3]
        @old_rank_2.parent = @group;
        @old_rank_2.save
        expect(@old_rank_2.reload.rank).to eq 1
        expect(@old_rank_3.reload.rank).to eq 2 # Should move up one.
        expect(@old_rank_4.reload.rank).to eq 3 # Should move up one.
      end

      it 'should change order of the questioning moved higher' do
        @qing = @f.c[3]
        @qing.move_higher
        expect(@f.c[3].rank).to be < @f.c[2].rank
      end

      it 'should change order of the questioning moved lower' do
        @qing = @f.c[0]
        @qing.move_lower
        expect(@f.c[1].rank).to be < @f.c[0].rank
      end
    end

    context "with nested form" do
      before do
        @f = create(:form, question_types: ['text', ['text', 'text']])
      end

      it 'should work when changing ranks of second level items' do
        @q1, @q2 = @f.c[1].children
        @q2.update_attributes!(rank: 1)
        expect(@q1.reload.rank).to eq 2
        expect(@q2.reload.rank).to eq 1
      end
    end
  end
end
