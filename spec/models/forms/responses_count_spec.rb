# frozen_string_literal: true

require "rails_helper"

describe "Form#responses_count" do
  let(:user) { create(:user) }
  let!(:form1) { create(:form, question_types: %w[integer]) }
  let!(:form2) { create(:form, question_types: %w[integer]) }
  let!(:form3) { create(:form, question_types: %w[integer]) }
  let(:forms_by_id) { scope.index_by(&:id) }

  shared_examples_for "correct counts" do |responses_counts, query_count|
    it "counts should all be correct and use a given number of queries" do
      Response.count # Force preloading of Response model info which can cause an irrelevant query.
      expect do
        expect(forms_by_id[form1.id].responses_count).to eq(responses_counts[0])
        expect(forms_by_id[form2.id].responses_count).to eq(responses_counts[1])
        expect(forms_by_id[form3.id].responses_count).to eq(responses_counts[2])
      end.to make_database_queries(count: query_count)
    end
  end

  context "with no responses" do
    context "without eager load" do
      let(:scope) { Form.all }
      it_behaves_like "correct counts", [0, 0, 0], 4
    end

    context "with eager load" do
      let(:scope) { Form.with_responses_counts }
      it_behaves_like "correct counts", [0, 0, 0], 1
    end
  end

  context "with some responses and one deleted" do
    let!(:response1) { create(:response, user: user, form: form1, answer_values: %w[1]) }
    let!(:response2) { create(:response, user: user, form: form1, answer_values: %w[1]) }
    let!(:response3) { create(:response, user: user, form: form1, answer_values: %w[1]) }
    let!(:response4) { create(:response, user: user, form: form2, answer_values: %w[1]) }
    let!(:response5) { create(:response, user: user, form: form3, answer_values: %w[1]) }
    let!(:response6) { create(:response, user: user, form: form3, answer_values: %w[1]) }

    before { response3.destroy }

    context "without eager load" do
      let(:scope) { Form.all }
      it_behaves_like "correct counts", [2, 1, 2], 4
    end

    context "with eager load" do
      let(:scope) { Form.with_responses_counts }
      it_behaves_like "correct counts", [2, 1, 2], 1
    end
  end
end
