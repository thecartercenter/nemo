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
      @qing_group.ancestry = @qing.id
      @qing_group.save
      expect(@qing.check_ancestry_integrity(@qing_group.id)).to be_falsy
    end
  end

  describe "sort" do
    before(:each) do
      @f = create(:form, questions: ['text', 'text', 'text', 'text'])
      @group = create(:qing_group, form: @f, ancestry: @f.root_group.id)
    end

    it 'should create 4 questionings and one group with correct rank' do
      expect(@f.c.size).to eq(5)
      expect(@f.c[0].rank).to be < @f.c[1].rank
      expect(@f.c[1].rank).to be < @f.c[2].rank
      expect(@f.c[2].rank).to be < @f.c[3].rank
    end

    it 'should assign a rank to a newly created group' do
      expect(@f.c[2].rank).to be < @group.rank
    end

    it 'should set rank to 0 for existing questioning moved to the empty group' do
      @qing = @f.c[0]
      @qing.ancestry = "#{@f.root_group.id}/#{@group.id}"
      @qing.save
      @qing.reload
      expect(@qing.rank).to eq 0
    end

    it 'should change order of the rearranged questioning in the group' do
      @qing = @f.c[3]
      @qing.update_attribute :rank_position, :up
      expect(@f.c[2].rank).to be > @f.c[3].rank
    end
  end
end
