require "spec_helper"

# We need to clean with truncation here b/c we use hard coded id's in expectation.
describe "form rendering for odk", clean_with_truncation: true do
  let(:user) { create(:user) }
  let(:form) { create(:form) }

  before do
    login(user)
    get(form_path(form, format: :xml))
  end

  context "sample form" do
    let!(:form) do
      create(:form, :published, :with_version,
        version: "abc", question_types: %w(text long_text integer decimal location select_one
          multilevel_select_one select_multiple datetime date time))
    end

    it "should render proper xml" do
      expect(response).to be_success
      expect(response.body).to match_xml expectation_file("odk/sample_form.xml")
    end
  end

  context "grid form" do
    let(:first_question) { create(:question, qtype_name: "select_one") }
    let(:second_question) { create(:question, qtype_name: "select_one", option_set: first_question.option_set) }
    let(:form) do
      create(:form, :published, :with_version, version: "abc", questions: [[first_question, second_question]])
    end

    it "should render proper xml" do
      expect(response).to be_success
      puts response.body
      expect(response.body).to match_xml expectation_file("odk/grid_form.xml")
    end
  end

  context "form with & in option name" do
    let(:option_set) { create(:option_set, option_names: ["Salt & Pepper", "Peanut Butter & Jelly"]) }
    let(:question) { create(:question, option_set: option_set) }
    let(:form) { create(:form, :published, :with_version, version: "abc", questions: [question] ) }

    it "should not have parsing errors" do
      expect(response).to be_success
      doc = Nokogiri::XML(response.body) { |config| config.noblanks }
      expect(doc.errors).to be_empty
    end
  end

  context "media question form" do
    let(:form) do
      create(:form, :published, :with_version,
        version: "abc", question_types: %w(text image annotated_image sketch signature audio video))
    end

    it "should render proper XML" do
      expect(response).to be_success
      expect(response.body).to match_xml expectation_file("odk/media_question_form.xml")
    end
  end

  context "group form" do
    let(:form) do
      form = create(:form, :published, :with_version,
        version: "abc", question_types: [["text", "text", "text", "text"]])
      form.questionings.last.update_attributes!(hidden: true, required: true)
      form
    end

    it "should render proper xml" do
      expect(response).to be_success
      puts response.body
      expect(response.body).to match_xml expectation_file("odk/group_form.xml")
    end
  end

  context "repeat group form" do
    let(:form) do
      form = create(:form, :published, :with_version,
        version: "abc", question_types: [["text", "text", "text", "text"]])
      form.questionings.last.update_attributes!(hidden: true, required: true)
      form.child_groups.first.update_attributes!(repeatable: true)
      form
    end

    it "should render proper xml" do
      expect(response).to be_success
      puts response.body
      expect(response.body).to match_xml expectation_file("odk/repeat_group_form.xml")
    end
  end

  context "nested repeat group form" do
    let(:form) do
      form = create(:form, :published, :with_version, version: "abc",
      question_types:
        [
          {repeating:
            {
              items:
                ["text", #q1
                  "text", #q2
                  {
                    repeating:
                      {
                        items: ["integer", "integer"], #q3,q4
                        name: "Repeat Group A"
                      }
                  },
                  "long_text" #q5
                ],
                name: "Repeat Group 1"
            }
          },
          "text", #q6
           {
            repeating: {
              items: ["text"], #q7
              name: "Repeat Group 2"
            }
          }
      ])
    end

    it "should render proper xml" do
      expect(response).to be_success
      puts response.body
      expect(response.body).to match_xml expectation_file("odk/nested_repeat_group_form.xml")
    end
  end

  context "group form with multilevel select" do
    let(:form) do
      create(:form, :published, :with_version,
        version: "abc", question_types: [["text", "date", "multilevel_select_one", "integer"]])
    end

    it "should render proper xml" do
      expect(response).to be_success

      puts response.body
      expect(response.body).to match_xml expectation_file("odk/group_form_with_multilevel.xml")
    end
  end

  context "repeat group form with multilevel select" do
    let(:form) do
      form = create(:form, :published, :with_version,
        version: "abc", question_types: [["text", "date", "multilevel_select_one", "integer"]])
      form.child_groups.first.update_attributes!(repeatable: true)
      form
    end

    it "should render proper xml" do
      expect(response).to be_success
      #puts response.body
      expect(response.body).to match_xml expectation_file("odk/repeat_group_form_with_multilevel.xml")
    end
  end
end
