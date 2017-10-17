# There are more report tests in test/unit/report.
require "spec_helper"

describe Report::ListReport, :reports do
  it_behaves_like "has a uuid"

  context "with multilevel option set" do
    before do
      @form = create(:form, question_types: %w(multilevel_select_one integer multilevel_select_one))
      @response1 = create(:response, form: @form, answer_values: [["Animal", "Cat"], 5, ["Animal", "Dog"]])
      @response2 = create(:response, form: @form, answer_values: [["Animal"], 10, ["Plant", "Oak"]])
      @response3 = create(:response, form: @form, answer_values: [nil, 15, ["Plant"]])
      @report = create(:list_report, _calculations: @form.questions + ["response_id"])
    end

    it "should have answer values in correct order" do
      expect(@report).to have_data_grid(
        @form.questions.map(&:name) + ["Response ID"],
        ["Animal, Cat", "5",  "Animal, Dog", "#{@response1.shortcode}"],
        ["Animal",      "10", "Plant, Oak",  "#{@response2.shortcode}"],
        ["_",           "15", "Plant",       "#{@response3.shortcode}"]
      )
    end
  end

  context "with non-english locale" do
    before do
      I18n.locale = :fr
      @form = create(:form, question_types: %w(integer integer))
      @response = create(:response, form: @form, answer_values: [5, 10])
      @report = create(:list_report, _calculations: @form.questions + ["form"])
    end

    it "should have proper headers" do
      expect(@form.questions[0].name_fr).to match(/Question/) # Ensure question created with french name.
      expect(@report).to have_data_grid(
        @form.questions.map(&:name_fr) + ["Fiche"],
        %w(5 10) + [@form.name]
      )
    end

    after do
      I18n.locale = :en
    end
  end

  describe "results" do
    it "basic list" do
      user = create(:user, name: "Foo")
      questions = []
      questions << create(:question, code: "Inty", qtype_name: "integer")
      questions << create(:question, code: "State", qtype_name: "text")
      form = create(:form, questions: questions)
      create(:response, form: form, user: user, source: "odk", answer_values: %w(10 ga))
      create(:response, form: form, user: user, source: "web", answer_values: %w(3 ga))
      create(:response, form: form, user: user, source: "web", answer_values: %w(5 al))

      # Ensure destroyed data is ignored
      decoy = create(:response, form: form, user: user, source: "web", answer_values: %w(5 al))
      decoy.destroy

      report = create_report("List", calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"},
        {rank: 2, type: "Report::IdentityCalculation", question1_id: questions[0].id},
        {rank: 3, type: "Report::IdentityCalculation", question1_id: questions[1].id},
        {rank: 4, type: "Report::IdentityCalculation", attrib1_name: "source"}
      ])

      expect(report).to have_data_grid(
        ["Submitter Name"] + %w( Inty  State   Source ),
        %w( Foo                  10    ga      odk    ),
        %w( Foo                  3     ga      web    ),
        %w( Foo                  5     al      web    ))
    end

    it "list with select one" do
      user = create(:user, name: "Foo")
      yes_no = create(:option_set, option_names: %w(Yes No))
      questions = []
      questions << create(:question, code: "Inty", qtype_name: "integer")
      questions << create(:question, code: "State", qtype_name: "text")
      questions << create(:question, code: "Happy", qtype_name: "select_one", option_set: yes_no)
      form = create(:form, questions: questions)
      create(:response, form: form, user: user, source: "odk", answer_values: %w(10 ga Yes))
      create(:response, :is_reviewed, form: form, user: user, source: "web", answer_values: %w(3 ga No), reviewer_name: "Reviewer")
      create(:response, :is_reviewed, form: form, user: user, source: "web", answer_values: %w(5 al No), reviewer_name: "Michelle")

      report = create_report("List", calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"},
        {rank: 2, type: "Report::IdentityCalculation", question1_id: questions[0].id},
        {rank: 3, type: "Report::IdentityCalculation", question1_id: questions[1].id},
        {rank: 4, type: "Report::IdentityCalculation", attrib1_name: "source"},
        {rank: 5, type: "Report::IdentityCalculation", attrib1_name: "reviewed"},
        {rank: 6, type: "Report::IdentityCalculation", attrib1_name: "reviewer"},
        {rank: 7, type: "Report::IdentityCalculation", question1_id: questions[2].id}
      ])

      expect(report).to have_data_grid(
        ["Submitter Name"] + %w( Inty  State   Source  Reviewed Reviewer  Happy ),
        %w( Foo                  10    ga      odk     No       _         Yes   ),
        %w( Foo                  3     ga      web     Yes      Reviewer  No    ),
        %w( Foo                  5     al      web     Yes      Michelle  No    ))
    end

    it "response and list reports using same attrib" do
      user = create(:user, name: "Foo")
      question = create(:question, code: "Inty", qtype_name: "integer")
      form = create(:form, questions: [question])
      create(:response, form: form, user: user, answer_values: %w(10))
      create(:response, form: form, user: user, answer_values: %w(3))

      report = create_report("List", calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"},
      ])

      expect(report).to have_data_grid(
        ["Submitter Name"] + %w(),
        %w( Foo                 ),
        %w( Foo                 ))

      report = create_report("ResponseTally", calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"}
      ])

      expect(report).to have_data_grid(
        %w( Tally TTL ),
        %w( Foo      2   2 ),
        %w( TTL      2   2 ))
    end

    context "with multiple forms that share a partial name" do
      let!(:questions) { [ create(:question, code: "Inty", qtype_name: "integer") ] }
      let!(:first_form) { create(:form, name: "SampleForm", questions: questions) }
      let!(:second_form) { create(:form, name: "SampleForm A", questions: questions) }
      let!(:third_form) { create(:form, name: "SampleB Form", questions: questions) }
      let!(:responses) do
        [
          create(:response, form: first_form, answer_values: %w(1)),
          create(:response, form: second_form, answer_values: %w(2)),
          create(:response, form: third_form, answer_values: %w(3))
        ]
      end
      let(:report) do
        create(:list_report,
          filter: %{exact-form:("SampleForm")},
          _calculations: ["form"] + questions,
          question_labels: "code"
        )
      end

      it "only includes the exact matching form" do
        expect(report).to have_data_grid(
          %w(Form          Inty),
          %w(SampleForm    1)
        )
      end
    end
  end

  context "with date & time attribs and answers" do
    let(:form) { create(:form, question_types: %w(integer)) }
    let!(:response) { create(:response, form: form, answer_values: ["123"]) }
    let(:report) do
      create_report("List", calculations_attributes: [
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

      report.run

      # date_submitted should be converted to right timezone
      expect(report.data.rows[0][0]).to eq "Jan 01 2017"
    end
  end
end
