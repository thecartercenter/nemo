# frozen_string_literal: true

require "rails_helper"
require "fileutils"

describe "form rendering for odk", :odk, :reset_factory_sequences do
  let(:user) { create(:user) }
  let(:form) { create(:form) }

  # Set this to true temporarily to make the spec save the prepared XML files under `tmp/odk_test_forms`.
  # Then use `adb push tmp/odk/forms /sdcard/odk` or similar to load them into ODK for testing.
  let(:save_fixtures) { true }

  before do
    login(user)
  end

  context "sample form" do
    let!(:form) do
      create(:form,
        :published,
        :with_version,
        name: "Sample",
        question_types: %w[text long_text integer decimal location select_one
                           multilevel_select_one select_multiple text
                           datetime date time formstart formend barcode])
    end

    before do
      # Include a hidden question.
      # Hidden questions should be included in the bind and instance sections but nowhere else.
      # Required flag should be ignored for hidden questions.
      # This is so they can be used for prefilled data.
      form.sorted_children[8].update!(hidden: true, required: true)

      # Include multiple conditions on one question.
      form.c[6].display_conditions.create!(ref_qing: form.c[2], op: "gt", value: "5")
      form.c[6].display_conditions.create!(ref_qing: form.c[5], op: "eq",
                                           option_node: form.c[5].option_set.c[0])
      form.c[6].update!(display_if: "all_met")
    end

    it "should render proper xml" do
      expect_xml(form, "sample_form.xml")
    end
  end

  context "counter form" do
    let!(:form) do
      create(:form, :published, :with_version, name: "Counter", question_types: %w[counter counter_with_inc])
    end

    it "should render proper xml" do
      expect_xml(form, "counter_form.xml")
    end
  end

  context "grid group with display condition" do
    let!(:form) do
      create(:form, :published, :with_version,
        name: "Grid Group with Condition", question_types: ["text", %w[select_one select_one], "text"])
    end

    before do
      # Make the grid questions required since we need to be careful that the hidden label row
      # is not marked required.
      form.c[1].c.each { |qing| qing.update!(required: true) }

      # Ensure both group questions have same option set.
      form.c[1].c[1].question.update!(option_set_id: form.c[1].c[0].question.option_set_id)

      # Add condition to group.
      form.c[1].display_conditions.create!(ref_qing: form.c[0], op: "eq", value: "foo")
      form.c[1].update!(display_if: "all_met")
    end

    it "should render proper xml" do
      expect_xml(form, "grid_group_with_condition.xml")
    end
  end

  context "gridable form with one_screen set to false" do
    let(:q1) { create(:question, qtype_name: "select_one") }
    let(:q2) { create(:question, qtype_name: "select_one", option_set: q1.option_set) }
    let(:form) do
      create(:form, :published, :with_version, name: "Multi-screen Gridable", questions: [[q1, q2]])
    end

    before do
      form.sorted_children[0].update!(one_screen: false)
    end

    it "should not render with grid format" do
      expect_xml(form, "multiscreen_gridable_form.xml")
    end
  end

  context "form with & in option name" do
    let(:option_set) { create(:option_set, option_names: ["Salt & Pepper", "Peanut Butter & Jelly"]) }
    let(:question) { create(:question, option_set: option_set) }
    let(:form) do
      create(:form, :published, :with_version,
        name: "Form with & in Option",
        questions: [question])
    end

    it "should not have parsing errors" do
      do_request_and_expect_success
      doc = Nokogiri::XML(response.body, &:noblanks)
      expect(doc.errors).to be_empty
    end
  end

  context "media question form" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Media Questions",
        question_types: %w[text image annotated_image sketch signature audio video])
    end

    it "should render proper xml" do
      expect_xml(form, "media_question_form.xml")
    end
  end

  context "group form" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Basic Group",
        question_types: ["text", %w[text text text]])
    end

    before do
      # Test conditions on groups.
      form.c[1].display_conditions.create!(ref_qing: form.c[0], op: "eq", value: "foo")
      form.c[1].update!(display_if: "all_met")
    end

    it "should render proper xml" do
      expect_xml(form, "group_form.xml")
    end
  end

  context "group form with condition" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Group with Condition",
        question_types: [{repeating: {name: "Group A", items: %w[text text text]}}])
    end

    before do
      form.questionings.last.display_conditions.create!(
        ref_qing: form.questionings.first,
        op: "eq",
        value: "foo"
      )
      form.questionings.last.update!(display_if: "all_met")
    end

    it "should not render on single page due to condition" do
      expect_xml(form, "group_form_with_condition.xml")
    end
  end

  context "multiscreen group form" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Multi-screen Group",
        question_types: [%w[text text text]])
    end

    before do
      form.sorted_children[0].update!(one_screen: false)
    end

    it "should render proper xml" do
      expect_xml(form, "multiscreen_group_form.xml")
    end
  end

  context "repeat group form with dynamic item names" do
    let!(:form) do
      create(:form, :published, :with_version,
        name: "Repeat Group",
        question_types: [
          {repeating: {name: "Grp1", item_name: %(Hi' "$Name"), items: %w[text text text]}},

          # Include a normal group to ensure differentiated properly.
          %w[text text],

          # Second repeat group, one_screen false. Item name includes escapable chars (>).
          {repeating: {
            name: "Grp2",
            item_name: %{calc(if($Age > 18, 'A’"yeah"', 'C'))},
            items: %w[integer text]
          }}
        ])
    end

    before do
      form.c[0].c[0].question.update!(code: "Name")
      form.c[2].update!(one_screen: false)
      form.c[2].c[0].question.update!(code: "Age")
    end

    it "should render proper xml" do
      expect_xml(form, "repeat_group_form.xml")
    end
  end

  context "nested repeat group form" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Nested Repeat Group",
        version: "abc",
        question_types: [
          {repeating:
            {
              items:
                ["text", # q1
                 "text", # q2
                 {
                   repeating:
                     {
                       items: %w[integer text], # q3,q4
                       name: "Repeat Group A"
                     }
                 },
                 "long_text"], # q5
              name: "Repeat Group 1"
            }},
          "text", # q6
          {
            repeating: {
              items: %w[text], # q7
              name: "Repeat Group 2"
            }
          }
        ])
    end

    before do
      form.questioning_with_code("TextQ4").update!(default: "$TextQ2-$!RepeatNum")
      form.questioning_with_code("TextQ7").update!(default: "$TextQ2-$!RepeatNum")
    end

    it "should render proper xml" do
      expect_xml(form, "nested_repeat_group_form.xml")
    end
  end

  context "empty repeat group" do
    let!(:form) do
      create(:form, :published, :with_version,
        name: "Empty Repeat Group",
        question_types: ["text", {repeating: {name: "Repeat Group 1", items: []}}])
    end

    it "should render proper xml" do
      expect_xml(form, "empty_repeat_group_form.xml")
    end
  end

  context "group form with multilevel select" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Group with Multilevel Select",
        question_types: [%w[text date multilevel_select_one integer]])
    end

    it "should render proper xml" do
      expect_xml(form, "group_form_with_multilevel.xml")
    end
  end

  context "multiscreen group form with multilevel select" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Multi-screen Group with Multilev",
        question_types: [%w[text date multilevel_select_one integer]])
    end

    before do
      form.sorted_children[0].update!(one_screen: false)
    end

    it "should render proper xml" do
      expect_xml(form, "multiscreen_group_form_with_multilevel.xml")
    end
  end

  context "repeat group form with multilevel select" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Repeat Group with Multilevel",
        question_types: [%w[text date multilevel_select_one integer]])
    end

    before do
      form.child_groups.first.update!(repeatable: true)
    end

    it "should render proper xml" do
      expect_xml(form, "repeat_group_form_with_multilevel.xml")
    end
  end

  context "nested group form with multilevel select" do
    let(:form) do
      create(:form, :published, :with_version,
        name: "Nested Group with Multilevel",
        version: "abc",
        question_types: [
          {repeating:
            {
              name: "Repeat Group 1",
              items:
                [
                  "text", # q1
                  "text", # q2
                  {
                    repeating:
                      {
                        name: "Repeat Group A",
                        items: %w[integer multilevel_select_one] # q3,q4
                      }
                  },
                  "long_text" # q5
                ]
            }}
        ])
    end

    it "should render proper xml" do
      expect_xml(form, "nested_group_form_with_multilevel.xml")
    end
  end

  context "form with dynamic patterns" do
    let(:form) do
      create(:form, :published, :with_version,
        default_response_name: %("$MSO" --> $TXT's), # We use a > and ' on purpose so we test escaping.
        name: "Default Patterns",
        question_types: [%w[integer text select_one multilevel_select_one], "text"])
    end

    before do
      # Set codes for use in default_response_name
      form.c[0].c[0].update!(code: "INT")
      form.c[0].c[3].update!(code: "MSO")
      form.c[1].update!(code: "TXT", default: %{calc(if($INT > 5, '"a"', 'b'))})
    end

    it "should render proper xml" do
      expect_xml(form, "default_pattern_form.xml")
    end
  end

  context "form with incomplete responses allowed" do
    let(:form) do
      create(:form, :published, :with_version, name: "Allows Incomplete",
                                               question_types: %w[integer], allow_incomplete: true)
    end

    before do
      # Things don't get interesting unless you have at least one required question.
      form.c[0].update!(required: true)
    end

    it "should render proper xml" do
      expect_xml(form, "allows_incomplete.xml")
    end
  end

  context "form with skip rule and display conditions" do
    let!(:form) do
      create(:form, :published, :with_version, name: "Skip Rule and Conditions",
                                               question_types: %w[text long_text integer decimal location
                                                                  select_one multilevel_select_one
                                                                  select_multiple text datetime])
    end

    before do
      form.sorted_children[8].update!(hidden: true, required: true)

      # Include multiple conditions on one question.
      form.c[6].display_conditions.create!(ref_qing: form.c[2], op: "gt", value: "5")
      form.c[6].display_conditions.create!(ref_qing: form.c[5],
                                           op: "eq",
                                           option_node: form.c[5].option_set.c[0])
      form.c[6].update!(display_if: "all_met")
      create(:skip_rule,
        source_item: form.c[2],
        destination: "item",
        dest_item_id: form.c[7].id,
        skip_if: "all_met",
        conditions_attributes: [{ref_qing_id: form.c[2].id, op: "eq", value: 0}])
    end

    it "should render proper xml" do
      expect_xml(form, "form_with_skip_rule.xml")
    end
  end

  context "form with audio prompts" do
    let(:form) { create(:form, :published, question_types: %w[integer]) }

    before do
      form.c[0].question.update!(audio_prompt: audio_fixture("powerup.mp3"))
    end

    it "should render proper xml" do
      expect_xml(form, "form_with_audio_prompt.xml")
    end
  end

  def expect_xml(form, filename)
    do_request_and_expect_success
    expect(tidyxml(response.body)).to eq prepare_odk_form_fixture(filename, form)
  end

  def do_request_and_expect_success
    get(form_path(form, format: :xml))
    expect(response).to be_success
  end

  def prepare_odk_form_fixture(filename, form, options = {})
    path = "odk/forms/#{filename}"
    prepare_odk_fixture(filename, path, form, options)
  end
end
