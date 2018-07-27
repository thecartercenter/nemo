# frozen_string_literal: true

require "rails_helper"

describe ResponseDecorator do
  let(:user) { create(:user) }
  let(:form) { create(:form, :published, question_types: %w[integer]) }
  let(:response) { create(:response, user: user, form: form, answer_values: [1]) }
  let(:context) { {answer_finder: AnswerFinder.new(Response.where(id: response.id))} }
  let(:decorator) { ResponseDecorator.new(response, context: context) }
  let!(:other_question) { create(:question) }

  it "should return shortcode in upper case" do
    expect(decorator.shortcode).to eq response.shortcode.upcase
  end

  it "should return answer to the valid question" do
    expect(decorator.answer_for(form.questions.first)).to eq response.root_node.c[0]
    expect(decorator.answer_for(other_question)).to be_nil
  end
end
