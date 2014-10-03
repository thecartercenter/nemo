require "spec_helper"

describe Form do

  context "API User" do
    before do
      @api_user = FactoryGirl.create(:user)
      @mission = FactoryGirl.create(:mission, name: "test mission")
      @form = FactoryGirl.create(:form, mission: @mission, name: "something", access_level: 'protected')
      @form.whitelist_users.create(user_id: @api_user.id)
    end

    it "should return true for user in whitelist" do
      expect(@form.api_user_id_can_see?(@api_user.id)).to be_truthy
    end

    it "should return false for user not in whitelist" do
      other_user = FactoryGirl.create(:user)
      expect(@form.api_user_id_can_see?(other_user.id)).to be_falsey
    end
  end

  describe 'update_ranks' do
    before do
      # Create form with condition (#3 referring to #2)
      @form = create(:form, question_types: %w(integer select_one integer))
      @qings = @form.questionings
      @qings[2].create_condition(ref_qing: @qings[1], op: 'eq', option: @qings[1].options[0])

      # Move question #1 down to position #3 (old #2 and #3 shift up one).
      @old_ids = @qings.map(&:id)

      # Without this, this test was not raising a ConditionOrderingError that was getting raised in the wild.
      # ORM can be a pain sometimes!
      @form.reload

      @form.update_ranks(@old_ids[0] => 3, @old_ids[1] => 1, @old_ids[2] => 2)
      @form.save!
    end

    it 'should update ranks and not raise order invalidation error' do
      expect(@form.reload.questionings.map(&:id)).to eq [@old_ids[1], @old_ids[2], @old_ids[0]]
    end
  end
end
