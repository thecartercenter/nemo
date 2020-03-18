# frozen_string_literal: true

require "rails_helper"

describe Results::AnswerSearchVectorUpdater do
  let!(:form) do
    create(:form, question_types: %w[select_one select_multiple select_one]).tap do |f|
      # First two questions will have same option set, third (decoy) will not.
      f.c[1].question.update!(option_set: f.c[0].option_set)
    end
  end
  let!(:response) { create(:response, form: form, answer_values: ["Cat", %w[Cat Dog], "Cat"]) }
  let(:option_node) { form.c[0].option_set.c[0] }

  it "sets tsv on answer creation" do
    expect(response.c[0].tsv).to eq("'cat':1")
  end

  it "when option udpated, updates search index tsv on both answers but not decoy" do
    option_node.option.assign_attributes(name_en: "Kitty")
    option_node.save!
    response.reload
    expect(response.c[0].tsv).to eq("'kitty':1")
    expect(response.c[1].tsv).to match(/\A'dog':\d 'kitty':\d\z/)
    expect(response.c[2].tsv).to eq("'cat':1")
  end
end
