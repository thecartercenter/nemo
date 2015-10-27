require "spec_helper"

describe QingGroup do

  context "One QingGroup" do
    before do
      @form = FactoryGirl.create(:sample_form, question_types: [['text', 'text', 'text']])
      group = create(:qing_group, form: @form, ancestry: @form.root_group.id)
    end

    it "should return a list of groups" do
      expect(QingGroup.child_groups(@form.root_group.children).count).to eq(2)
    end

  end

end
