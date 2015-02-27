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
end
