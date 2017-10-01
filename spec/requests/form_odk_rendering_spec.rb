require "spec_helper"
require "fileutils"

describe "form rendering for odk",:odk, :reset_factory_sequences do
  let(:user) { create(:user) }
  let(:form) { create(:form) }

  # Set this to true temporarily to make the spec save the prepared XML files under `tmp/odk_test_forms`.
  # Then use `adb push tmp/odk_test_forms /sdcard/odk/forms` or similar to load them into ODK for testing.
  let(:save_expectations) { false }

  before do
    login(user)
  end

  context "sample form" do
    let!(:form) do
      create(:form, :published, :with_version, name: "Sample", default_response_name: "$Q0 - $Q1",
        question_types: %w(text long_text integer decimal location select_one
          multilevel_select_one select_multiple text datetime date time formstart formend))
    end

    before do
      # Include a hidden question.
      # Hidden questions should be included in the bind and instance sections but nowhere else.
      # Required flag should be ignored for hidden questions.
      # This is so they can be used for prefilled data.
      form.sorted_children[8].update_attributes!(hidden: true, required: true)

      # Set codes for use in default_response_name
      [0, 1].each { |i| form.c[i].update!(code: "Q#{i}") }
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("sample_form.xml", form)
    end
  end

  context "counter form" do
    let!(:form) do
      create(:form, :published, :with_version, name: "Counter", question_types: %w(counter counter_with_inc))
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("counter_form.xml", form)
    end
  end

  context "grid form" do
    let(:first_question) { create(:question, qtype_name: "select_one") }
    let(:second_question) { create(:question, qtype_name: "select_one", option_set: first_question.option_set) }
    let(:form) do
      create(:form, :published, :with_version,
        name: "Grid",
        questions: [[first_question, second_question]]
      )
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("grid_form.xml", form)
    end
  end

  context "gridable form with one_screen set to false" do
    let(:first_question) { create(:question, qtype_name: "select_one") }
    let(:second_question) { create(:question, qtype_name: "select_one", option_set: first_question.option_set) }
    let(:form) do
      create(:form, :published, :with_version,
        name: "Multi-screen Gridable",
        questions: [[first_question, second_question]]
      )
    end

    before do
      form.sorted_children[0].update_attributes!(one_screen: false)
    end

    it "should not render with grid format" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("multiscreen_gridable_form.xml", form)
    end
  end

  context "form with & in option name" do
    let(:option_set) { create(:option_set, option_names: ["Salt & Pepper", "Peanut Butter & Jelly"]) }
    let(:question) { create(:question, option_set: option_set) }
    let(:form) do
      create(:form, :published, :with_version,
        name: "Form with & in Option",
        questions: [question]
      )
    end

    it "should not have parsing errors" do
      do_request_and_expect_success
      doc = Nokogiri::XML(response.body) { |config| config.noblanks }
      expect(doc.errors).to be_empty
    end
  end

  context "media question form" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Media Questions",
        question_types: %w(text image annotated_image sketch signature audio video)
      )
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("media_question_form.xml", form)
    end
  end

  context "group form" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Basic Group",
        question_types: [["text", "text", "text"]]
      )
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("group_form.xml", form)
    end
  end

  context "group form with condition" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Group with Condition",
        question_types: [{repeating: {name: "Group A", items: ["text", "text", "text"]}}]
      )
    end

    before do
      form.questionings.last.create_condition!(
        ref_qing: form.questionings.first,
        op: "eq",
        value: "foo"
      )
    end

    it "should not render on single page due to condition" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("group_form_with_condition.xml", form)
    end
  end

  context "multiscreen group form" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Multi-screen Group",
        question_types: [["text", "text", "text"]]
      )
    end

    before do
      form.sorted_children[0].update_attributes!(one_screen: false)
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("multiscreen_group_form.xml", form)
    end
  end

  context "repeat group form" do
    let!(:form) do
      create(:form, :published, :with_version,
        name: "Repeat Group",
        question_types: [
          {repeating: {name: "Repeat Group 1", items: ["text", "text", "text"]}},
          ["text", "text"] # Include a normal group to ensure differentiated properly.
        ]
      )
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("repeat_group_form.xml", form)
    end
  end

  context "nested repeat group form" do
    let(:form) do
      form = create(:form, :published, :with_version,
        name: "Nested Repeat Group",
        version: "abc",
        question_types: [
          {repeating:
            {
              items:
                ["text", #q1
                  "text", #q2
                  {
                    repeating:
                      {
                        items: ["integer", "text"], #q3,q4
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
        ]
      )
    end

    before do
      form.questioning_with_code("TextQ4").update_attributes!(default: "$TextQ2-$!RepeatNum")
      form.questioning_with_code("TextQ7").update_attributes!(default: "$TextQ2-$!RepeatNum")
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("nested_repeat_group_form.xml", form)
    end
  end

  context "group form with multilevel select" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Group with Multilevel Select",
        question_types: [["text", "date", "multilevel_select_one", "integer"]]
      )
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("group_form_with_multilevel.xml", form)
    end
  end

  context "multiscreen group form with multilevel select" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Multi-screen Group with Multilev",
        question_types: [["text", "date", "multilevel_select_one", "integer"]]
      )
    end

    before do
      form.sorted_children[0].update_attributes!(one_screen: false)
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq(
        prepare_odk_expectation("multiscreen_group_form_with_multilevel.xml", form))
    end
  end

  context "repeat group form with multilevel select" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Repeat Group with Multilevel",
        question_types: [["text", "date", "multilevel_select_one", "integer"]]
      )
    end

    before do
      form.child_groups.first.update_attributes!(repeatable: true)
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq prepare_odk_expectation("repeat_group_form_with_multilevel.xml", form)
    end
  end

  context "nested group form with multilevel select" do
    let(:form) do
      form = create(:form, :published, :with_version,
      name: "Nested Group with Multilevel",
      version: "abc",
      question_types: [
        {repeating:
          {
            name: "Repeat Group 1",
            items:
              ["text", #q1
                "text", #q2
                {
                  repeating:
                    {
                      name: "Repeat Group A",
                      items: ["integer", "multilevel_select_one"] #q3,q4
                    }
                },
                "long_text" #q5
              ]
            }
          }
        ]
      )
    end

    it "should render proper xml" do
      do_request_and_expect_success
      expect(tidyxml(response.body)).to eq(
        prepare_odk_expectation("nested_group_form_with_multilevel.xml", form))
    end
  end

  def do_request_and_expect_success
    get(form_path(form, format: :xml))
    expect(response).to be_success
  end

  def prepare_odk_expectation(filename, form)
    items = form.preordered_items.map { |i| Odk::DecoratorFactory.decorate(i) }
    nodes = items.map(&:preordered_option_nodes).uniq.flatten
    xml = prepare_expectation("odk/forms/#{filename}",
      formname: [form.name],
      form: [form.id],
      formver: [form.code],
      itemcode: items.map(&:odk_code),
      itemqcode: items.map(&:code),
      optcode: nodes.map(&:odk_code),
      optsetid: items.map(&:option_set_id).compact.uniq
    )
    if save_expectations
      dir = Rails.root.join("tmp", "odk_test_forms")
      FileUtils.mkdir_p(dir)
      File.open(dir.join(filename), "w") { |f| f.write(xml) }
    end
    xml
  end
end
