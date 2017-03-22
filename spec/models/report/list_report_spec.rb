# There are more report tests in test/unit/report.
require "spec_helper"

describe Report::ListReport, :reports do
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

  describe "results", no_sphinx: true do
    it "basic list" do
      user = create(:user, name: "Foo")
      questions = []
      questions << create(:question, code: "Inty", qtype_name: "integer")
      questions << create(:question, code: "State", qtype_name: "text")
      form = create(:form, questions: questions)
      create(:response, form: form, user: user, source: "odk", answer_values: %w(10 ga))
      create(:response, form: form, user: user, source: "web", answer_values: %w(3 ga))
      create(:response, form: form, user: user, source: "web", answer_values: %w(5 al))

      report = create_report("List", calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"},
        {rank: 2, type: "Report::IdentityCalculation", question1_id: questions[0].id},
        {rank: 3, type: "Report::IdentityCalculation", question1_id: questions[1].id},
        {rank: 4, type: "Report::IdentityCalculation", attrib1_name: "source"}
      ])

      expect(report).to have_data_grid(%w( Submitter  Inty  State   Source ),
        %w( Foo        10    ga      odk    ),
        %w( Foo        3     ga      web    ),
        %w( Foo        5     al      web    ))
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
        {rank: 5, type: "Report::IdentityCalculation", attrib1_name: "reviewer"},
        {rank: 6, type: "Report::IdentityCalculation", question1_id: questions[2].id}
      ])

      expect(report).to have_data_grid(%w( Submitter  Inty  State   Source  Reviewer  Happy ),
        %w( Foo        10    ga      odk     _         Yes   ),
        %w( Foo        3     ga      web     Reviewer  No    ),
        %w( Foo        5     al      web     Michelle  No    ))
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

      expect(report).to have_data_grid(%w( Submitter ),
        %w( Foo       ),
        %w( Foo       ))

      report = create_report("ResponseTally", calculations_attributes: [
        {rank: 1, type: "Report::IdentityCalculation", attrib1_name: "submitter"}
      ])

      expect(report).to have_data_grid(%w( Tally TTL ),
        %w( Foo      2   2 ),
        %w( TTL      2   2 ))
    end
  end
end
