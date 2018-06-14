require "spec_helper"

describe ResponseDecorator do
  let(:user) { create(:user) }
  let(:form) { create(:form, :published, question_types: %w(integer)) }
  let(:response) { create(:response, user: user, form: form, answer_values: [1]) }
  let(:context) { { answer_finder: AnswerFinder.new(Response.where(id: response.id)) }}
  let(:decorator) { ResponseDecorator.new(response, context: context) }
  let!(:other_question) { create(:question) }

  it 'should return id of the response' do
    actual = decorator.id
    expected = response.id
    expect(actual).to eq expected
  end

  it 'should return shortcode in upper case' do
    actual = decorator.shortcode
    expect(actual).to_not eq response.shortcode
    expect(actual).to eq response.shortcode.upcase
  end

  it 'should return answer to the valid question' do
    expect(decorator.answer_for(form.questions.first)).to eq response.answers.first
    expect(decorator.answer_for(other_question)).to_not be
  end
end