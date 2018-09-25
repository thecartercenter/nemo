# frozen_string_literal: true

require "rails_helper"

describe Results::ResponseDeleter do
  let(:form) { create(:form, question_types: %w[select_one select_multiple image]) }
  let!(:responses) do
    Array.new(4) do
      create(:response, form: form, answer_values: ["Cat", %w[Cat Dog], FactoryGirl.create(:media_image)])
    end
  end

  it "deletes everything if requested" do
    described_class.instance.delete(responses.map(&:id))
    expect(Response.count).to be_zero
    expect(Answer.count).to be_zero
    expect(Choice.count).to be_zero
    expect(Media::Object.count).to be_zero
  end

  it "deletes partially if requested" do
    described_class.instance.delete([responses.first.id])
    expect(Response.count).to eq(3)
    expect(Answer.count).to eq(9)
    expect(Choice.count).to eq(6)
    expect(Media::Object.count).to eq(3)
  end
end
