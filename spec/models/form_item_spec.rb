require "spec_helper"

describe FormItem do
  before do
    @user = create(:user, role_name: 'coordinator')
    @form = create(:form, question_types: ['text', ['text', 'text']])
    @qing = @form.c[0]
    @qing_group = @form.c[1]
  end

  describe "check_ancestry_integrity" do
    it "should return true" do
      expect(@qing.check_ancestry_integrity(@qing_group.id)).to be_truthy
    end

    it "should return false" do
      @qing_group.parent = @qing
      @qing_group.save
      expect(@qing.check_ancestry_integrity(@qing_group.id)).to be_falsy
    end
  end

  describe "sort" do
    before(:each) do
      @f = create(:form, questions: ['text', 'text', 'text', 'text'])
      @group = create(:qing_group, form: @f, parent: @f.root_group)
    end

    it 'should create 4 questionings and one group with correct ranks' do
      expect(@f.c.size).to eq(5)
      expect(@f.c[0].rank).to be < @f.c[1].rank
      expect(@f.c[1].rank).to be < @f.c[2].rank
      expect(@f.c[2].rank).to be < @f.c[3].rank
    end

    it 'should assign a rank to a newly created group' do
      expect(@f.c[2].rank).to be < @group.rank
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
end
