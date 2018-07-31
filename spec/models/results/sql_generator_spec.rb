require "rails_helper"

describe Results::SqlGenerator do
  let(:mission) { create(:mission) }
  let(:form) do
    create(:form,
      mission: mission,
      question_types: ["integer", "select_one", ["integer", "integer"], "select_multiple"]
    )
  end
  let!(:response) do
    create(:response,
      mission: mission,
      form: form,
      answer_values: [3, "Cat", [5, 6], %w(Cat Dog)]
    )
  end
  let!(:deleted_response) { create(:response, :deleted, mission: mission, form: form, answer_values: [3]) }
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
        answers.inst_num AS instance_num,
        answers.rank AS rank,
        answers.value AS value,
        answers.datetime_value AS datetime_value,
        answers.date_value AS date_value,
        answers.time_value AS time_value,
        answers.latitude AS latitude,
        answers.longitude AS longitude,
        COALESCE(ao.canonical_name, co.canonical_name) AS choice_name,
        option_sets.name AS option_set
      FROM \"responses\"
        LEFT JOIN users users ON responses.user_id = users.id AND users.deleted_at IS NULL
        INNER JOIN forms forms ON responses.form_id = forms.id AND forms.deleted_at IS NULL
        LEFT JOIN answers answers ON answers.response_id = responses.id AND answers.deleted_at IS NULL
          AND answers.type = 'Answer'
        INNER JOIN form_items questionings ON answers.questioning_id = questionings.id
          AND questionings.deleted_at IS NULL
        INNER JOIN questions questions ON questionings.question_id = questions.id
          AND questions.deleted_at IS NULL
        LEFT JOIN option_sets option_sets ON questions.option_set_id = option_sets.id
          AND option_sets.deleted_at IS NULL
        LEFT JOIN options ao ON answers.option_id = ao.id
          AND ao.deleted_at IS NULL
        LEFT JOIN option_nodes ans_opt_nodes ON ans_opt_nodes.option_id = ao.id
          AND ans_opt_nodes.option_set_id = option_sets.id AND ans_opt_nodes.deleted_at IS NULL
        LEFT JOIN choices choices ON choices.answer_id = answers.id AND choices.deleted_at IS NULL
        LEFT JOIN options co ON choices.option_id = co.id AND co.deleted_at IS NULL
        LEFT JOIN option_nodes ch_opt_nodes ON ch_opt_nodes.option_id = co.id
          AND ch_opt_nodes.option_set_id = option_sets.id AND ch_opt_nodes.deleted_at IS NULL
      WHERE \"responses\".\"deleted_at\" IS NULL AND (responses.mission_id = '#{mission.id}')
      ORDER BY responses.created_at DESC"))

    # 5 Answers, one row per answer, except two rows for the Answer with two Choices
    expect(Answer.find_by_sql(sql).size).to eq 6
  end

  def normalize(str)
    str.gsub(/\s+/m, " ")
  end
end
