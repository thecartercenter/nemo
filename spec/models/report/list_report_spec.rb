require "rails_helper"

describe Report::ListReport, :reports do
  include_context "reports"

  it "basic list" do
    user = create(:user, name: "Foo")
    questions = []
    questions << create(:question, code: "Inty", qtype_name: "integer")
    questions << create(:question, code: "State", qtype_name: "text")
    form = create(:form, questions: questions)
    create(:response, form: form, user: user, source: "odk", answer_values: %w[10 ga])
    create(:response, form: form, user: user, source: "web", answer_values: %w[3 ga])
    create(:response, form: form, user: user, source: "web", answer_values: %w[5 al])

    # Ensure destroyed data is ignored
    decoy = create(:response, form: form, user: user, source: "web", answer_values: %w[5 al])
    decoy.destroy

    report = create(:list_report, run: true, question_labels: "code", calculations_attributes: [
      {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"},
      {rank: 2, type: "Report::IdentityCalculation", question1_id: questions[0].id},
      {rank: 3, type: "Report::IdentityCalculation", question1_id: questions[1].id},
      {rank: 4, type: "Report::IdentityCalculation", attrib1_name: "source"}
    ])

    expect(report).to have_data_grid(
      ["Submitter Name"] + %w[Inty State Source],
      %w[Foo 10 ga odk],
      %w[Foo 3 ga web],
      %w[Foo 5 al web]
    )
  end

  context "with various question types" do
    let(:user) { create(:user, name: "Foo") }
    let(:yes_no) { create(:option_set, option_names: %w[Yes No], option_values: [1, 2]) }
    let(:colors) { create(:option_set, option_names: %w[Red Blue Green], option_values: [10, 11, 12]) }
    let(:questions) do
      [
        create(:question, code: "Inty", qtype_name: "integer"),
        create(:question, code: "State", qtype_name: "text"),
        create(:question, code: "Happy", qtype_name: "select_one", option_set: yes_no),
        create(:question, code: "Color", qtype_name: "select_multiple", option_set: colors)
      ]
    end
    let(:form) { create(:form, questions: questions) }
    subject(:report) do
      create(:list_report,
        run: {prefer_values: prefer_values},
        question_labels: "code",
        calculations_attributes: [
          {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"},
          {rank: 2, type: "Report::IdentityCalculation", question1_id: questions[0].id},
          {rank: 3, type: "Report::IdentityCalculation", question1_id: questions[1].id},
          {rank: 4, type: "Report::IdentityCalculation", attrib1_name: "source"},
          {rank: 5, type: "Report::IdentityCalculation", attrib1_name: "reviewed"},
          {rank: 6, type: "Report::IdentityCalculation", attrib1_name: "reviewer"},
          {rank: 7, type: "Report::IdentityCalculation", question1_id: questions[2].id},
          {rank: 8, type: "Report::IdentityCalculation", question1_id: questions[3].id}
        ])
    end

    before do
      create(:response, form: form, user: user, source: "odk", answer_values: %w[10 ga Yes])
      create(:response, :is_reviewed, form: form, user: user, source: "web", reviewer_name: "Reviewer",
                                      answer_values: ["3", "ga", "No", %w[Blue Green]])
      create(:response, :is_reviewed, form: form, user: user, source: "web", reviewer_name: "Michelle",
                                      answer_values: ["5", "al", "No", %w[Blue Red]])
    end

    context "with option names preferred" do
      let(:prefer_values) { false }

      it do
        is_expected.to have_data_grid(
          ["Submitter Name"] + %w[Inty State Source Reviewed Reviewer Happy Color],
          %w[Foo 10 ga odk No _ Yes _],
          %w[Foo 3 ga web Yes Reviewer No] << "Blue, Green",
          %w[Foo 5 al web Yes Michelle No] << "Red, Blue"
        )
      end
    end

    context "with option values preferred" do
      let(:prefer_values) { true }

      it do
        is_expected.to have_data_grid(
          ["Submitter Name"] + %w[Inty State Source Reviewed Reviewer Happy Color],
          %w[Foo 10 ga odk No _ 1 _],
          %w[Foo 3 ga web Yes Reviewer 2] << "11, 12",
          %w[Foo 5 al web Yes Michelle 2] << "10, 11"
        )
      end
    end
  end

  it "response and list reports using same attrib" do
    user = create(:user, name: "Foo")
    question = create(:question, code: "Inty", qtype_name: "integer")
    form = create(:form, questions: [question])
    create(:response, form: form, user: user, answer_values: %w[10])
    create(:response, form: form, user: user, answer_values: %w[3])

    report = create(:list_report, run: true, calculations_attributes: [
      {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"}
    ])

    expect(report).to have_data_grid(
      ["Submitter Name"] + %w[],
      %w[Foo],
      %w[Foo]
    )

    report = create(:response_tally_report, run: true, calculations_attributes: [
      {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"}
    ])

    expect(report).to have_data_grid(
      %w[Tally TTL],
      %w[Foo 2 2],
      %w[TTL 2 2]
    )
  end

  context "with multilevel option set" do
    let(:form) { create(:form, question_types: %w[multilevel_select_one integer multilevel_select_one]) }
    let!(:response1) { create(:response, form: form, answer_values: [%w[Animal Cat], 5, %w[Animal Dog]]) }
    let!(:response2) { create(:response, form: form, answer_values: [["Animal"], 10, %w[Plant Oak]]) }
    let!(:response3) { create(:response, form: form, answer_values: [nil, 15, ["Plant"]]) }
    let(:report) { create(:list_report, _calculations: form.questions + ["response_id"], run: true) }

    it "should have answer values in correct order" do
      expect(report).to have_data_grid(
        form.questions.map(&:name) + ["Response ID"],
        ["Animal, Cat", "5",  "Animal, Dog", response1.shortcode.to_s],
        ["Animal",      "10", "Plant, Oak",  response2.shortcode.to_s],
        ["_",           "15", "Plant",       response3.shortcode.to_s]
      )
    end
  end

  context "with non-english locale" do
    let(:form) { create(:form, question_types: %w[integer integer]) }
    let(:response) { create(:response, form: form, answer_values: [5, 10]) }
    let(:report) { create(:list_report, _calculations: form.questions + ["form"], run: true) }

    before do
      I18n.locale = :fr
      configatron.preferred_locales = %i[en fr]
      response
    end

    it "should have proper headers" do
      expect(form.questions[0].name_fr).to match(/Question/) # Ensure question created with french name.
      expect(report).to have_data_grid(
        form.questions.map(&:name_fr) + ["Fiche"],
        %w[5 10] + [form.name]
      )
    end
  end

  context "with multiple forms that share a partial name" do
    let!(:questions) { [create(:question, code: "Inty", qtype_name: "integer")] }
    let!(:first_form) { create(:form, name: "SampleForm", questions: questions) }
    let!(:second_form) { create(:form, name: "SampleForm A", questions: questions) }
    let!(:third_form) { create(:form, name: "SampleB Form", questions: questions) }
    let!(:responses) do
      [
        create(:response, form: first_form, answer_values: %w[1]),
        create(:response, form: second_form, answer_values: %w[2]),
        create(:response, form: third_form, answer_values: %w[3])
      ]
    end
    let(:report) do
      create(:list_report, filter: %{exact-form:("SampleForm")}, _calculations: ["form"] + questions,
                           question_labels: "code", run: true)
    end

    it "only includes the exact matching form" do
      expect(report).to have_data_grid(
        %w[Form Inty],
        %w[SampleForm 1]
      )
    end
  end

  context "with HTML response value" do
    it "sanitizes harmful tags" do
      user = create(:user, name: "Foo")
      questions = [create(:question, code: "Test", qtype_name: "text")]
      form = create(:form, questions: questions)
      create(:response,
        form: form, user: user, source: "odk",
        answer_values: ["<script>alert('hello');</script><b>There</b>"])

      report = create(:list_report, run: true, question_labels: "code", calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"},
        {rank: 2, type: "Report::IdentityCalculation", question1_id: questions[0].id}
      ])

      expect(report).to have_data_grid(
        ["Submitter Name", "Test"],
        ["Foo", "alert('hello');<b>There</b>"]
      )
    end
  end

  context "with date & time attribs and answers" do
    let(:form) { create(:form, question_types: %w[integer]) }
    let!(:response) { create(:response, form: form, answer_values: ["123"]) }
    let(:report) do
      create(:list_report, run: true, calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "date_submitted"}
      ])
    end

    around do |example|
      in_timezone("Saskatchewan") do
        # We use 22:00 because it will convert to Jan 2 when saved as UTC in DB
        Timecop.freeze("2017-01-01 22:00 -0600") do
          example.run
        end
      end
    end

    # This really should be happening for times as well in the Formatter class but it isn't.
    # Perhaps add it later once we decide what to do with reports.
    it "should convert fetched dates to current timezone" do
      # Timestamps and datetime_values are stored in UTC (note that the created_at day has jumped to Jan 2)
      expect(SqlRunner.instance.run("SELECT created_at FROM responses")[0]["created_at"].day).to eq 2

      # date_submitted should be converted to right timezone
      expect(report.data.rows[0][0]).to eq "Jan 01 2017"
    end
  end
end
