require "rails_helper"

describe "delete counter cache" do
  describe "Deleting responses" do
    let(:user) { create(:user) }
    let!(:form) { create(:form, question_types: %w(integer)) }
    let!(:response_1) { create(:response, form: form, user: user, answer_values: [1]) }
    let!(:response_2) { create(:response, form: form, user: user, answer_values: [1]) }
    let!(:response_3) { create(:response, form: form, user: user, answer_values: [1]) }

    it "should decrement the count with soft delete on response only" do
      response_1.destroy
      expect(form.responses.count).to eq 2
    end

    it "should decrement the count with soft delete on form" do
      form.responses.first.destroy
      expect(form.responses.count).to eq 2
    end

    it "should also update the count if actually destroyed" do
      response_2.destroy_fully!
      expect(form.responses.count).to eq 2
    end
  end
end
