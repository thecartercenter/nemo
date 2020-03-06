# frozen_string_literal: true

require "rails_helper"

describe Results::SqlGenerator do
  let(:mission) { create(:mission) }
  let(:form) do
    create(:form, mission: mission,
                  question_types: ["integer", "select_one", %w[integer integer], "select_multiple"])
  end
  let!(:response) do
    create(:response, mission: mission, form: form, answer_values: [3, "Cat", [5, 6], %w[Cat Dog]])
  end
  let(:other_mission) { create(:mission) }
  let(:other_form) { create(:form, mission: other_mission, question_types: ["integer"]) }
  let!(:other_response) { create(:response, mission: other_mission, form: other_form, answer_values: [3]) }
  let(:sql) { described_class.new(mission).generate }

  it "should generate valid SQL" do
    # Compare strings by normalizing whitespace
    expect(normalize(sql)).to eq(normalize("SELECT
        responses.id AS response_id,
        responses.created_at AS submission_time,
        responses.reviewed AS is_reviewed,
        forms.name AS form_name,
        questions.code AS question_code,
        questions.canonical_name AS question_name,
        questions.qtype_name AS question_type,
        users.name AS submitter_name,
        answers.id AS answer_id,
        answers.new_rank AS rank,
        answers.value AS value,
        answers.datetime_value AS datetime_value,
        answers.date_value AS date_value,
        answers.time_value AS time_value,
        answers.latitude AS latitude,
        answers.longitude AS longitude,
        COALESCE(ao.canonical_name, co.canonical_name) AS choice_name,
        option_sets.name AS option_set
      FROM \"responses\"
        LEFT JOIN users users ON responses.user_id = users.id
        INNER JOIN forms forms ON responses.form_id = forms.id
        LEFT JOIN answers answers ON answers.response_id = responses.id AND answers.type = 'Answer'
        INNER JOIN form_items questionings ON answers.questioning_id = questionings.id
        INNER JOIN questions questions ON questionings.question_id = questions.id
        LEFT JOIN option_sets option_sets ON questions.option_set_id = option_sets.id
        LEFT JOIN option_nodes ans_opt_nodes ON ans_opt_nodes.id = answers.option_node_id
        LEFT JOIN options ao ON ans_opt_nodes.option_id = ao.id
        LEFT JOIN choices choices ON choices.answer_id = answers.id
        LEFT JOIN option_nodes ch_opt_nodes ON ch_opt_nodes.id = choices.option_node_id
        LEFT JOIN options co ON ch_opt_nodes.option_id = co.id
      WHERE (responses.mission_id = '#{mission.id}')
      ORDER BY responses.created_at DESC"))

    # 5 Answers, one row per answer, except two rows for the Answer with two Choices
    expect(Answer.find_by_sql(sql).size).to eq(6)
  end

  def normalize(str)
    str.gsub(/\s+/m, " ")
  end
end
