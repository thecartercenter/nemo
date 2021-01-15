# frozen_string_literal: true

require "rails_helper"
require "fileutils"

describe "form rendering for odk", :odk, :reset_factory_sequences do
  let(:user) { create(:user) }
  let(:form) { create(:form) }
  let(:fixture_filename) { "#{fixture_name}.xml" }

  # Set this to true temporarily to make the spec save the prepared XML files under `tmp/odk/forms`.
  # Then use e.g. `adb push tmp/odk/forms/my_form/. /sdcard/odk/forms` to push one onto a phone for testing.
  let(:save_fixtures) { true }

  before do
    login(user)
  end

  context "form with various question types" do
    let!(:form) do
      create(:form, :live,
        name: "Sample",
        question_types: %w[text long_text integer decimal location select_one
                           multilevel_select_one select_multiple datetime date time
                           formstart formend barcode counter counter_with_inc])
    end

    before do
      # Include multiple conditions on one question.
      form.c[6].display_conditions.create!(left_qing: form.c[2], op: "gt", value: "5")
      form.c[6].display_conditions.create!(left_qing: form.c[5], op: "eq",
                                           option_node: form.c[5].option_set.c[0])
      form.c[6].update!(display_if: "all_met")
    end

    it "should render proper xml" do
      expect_xml(form, "various_question_types")
    end
  end

  context "form with incomplete responses allowed" do
    let(:form) do
      create(:form, :live, name: "Allows Incomplete", question_types: %w[integer], allow_incomplete: true)
    end

    before do
      # Things don't get interesting unless you have at least one required question.
      form.c[0].update!(required: true)
    end

    it "should render proper xml" do
      expect_xml(form, "allows_incomplete")
    end
  end

  context "display conditions, skip rules, constraints" do
    let!(:form) do
      create(:form, :live, name: "Conditional Logic",
                           question_types: %w[text long_text integer decimal location
                                              select_one multilevel_select_one
                                              select_multiple datetime integer integer])
    end

    before do
      # Include multiple conditions on one question.
      form.c[6].display_conditions.create!(left_qing: form.c[2], op: "gt", value: "5")
      form.c[6].display_conditions.create!(left_qing: form.c[5],
                                           op: "eq",
                                           option_node: form.c[5].option_set.c[0])
      form.c[6].update!(display_if: "all_met")
      create(:skip_rule,
        source_item: form.c[2],
        destination: "item",
        dest_item_id: form.c[7].id,
        skip_if: "all_met",
        conditions_attributes: [{left_qing_id: form.c[2].id, op: "eq", value: 0}])

      # Add both old style constraints and new style so we can check for the right expression.
      form.c[9].question.update!(minimum: 10, maximum: 100)
      form.c[9].constraints.create!(
        accept_if: "any_met",
        conditions_attributes: [
          {left_qing_id: form.c[3].id, op: "eq", value: 10},
          {left_qing_id: form.c[9].id, op: "eq", right_side_type: "qing", right_qing_id: form.c[2].id}
        ]
      )
      form.c[9].constraints.create!(
        accept_if: "all_met",
        conditions_attributes: [
          {left_qing_id: form.c[9].id, op: "neq", value: 55}
        ]
      )

      form.c[10].constraints.create!(
        accept_if: "all_met",
        conditions_attributes: [
          {left_qing_id: form.c[10].id, op: "eq", value: 10}
        ],
        rejection_msg_translations: {en: "Custom rejection message."}
      )
    end

    it "should render proper xml" do
      expect_xml(form, "conditional_logic")
    end
  end

  context "form with & in option name" do
    let(:option_set) { create(:option_set, option_names: ["Salt & Pepper", "Peanut Butter & Jelly"]) }
    let(:question) { create(:question, option_set: option_set) }
    let(:form) do
      create(:form, :live,
        name: "Form with & in Option",
        questions: [question])
    end

    it "should not have parsing errors" do
      do_request_and_expect_success
      doc = Nokogiri::XML(response.body, &:noblanks)
      expect(doc.errors).to be_empty
    end
  end

  describe "grids" do
    context "grid group with condition" do
      let!(:form) do
        create(:form, :live,
          name: "Grid Group with Condition", question_types: ["text", %w[select_one select_one], "text"])
      end

      before do
        # Make the grid questions required since we need to be careful that the hidden label row
        # is not marked required.
        form.c[1].c.each { |qing| qing.update!(required: true) }

        # Ensure both group questions have same option set.
        form.c[1].c[1].question.update!(option_set_id: form.c[1].c[0].question.option_set_id)

        # Add condition to group.
        form.c[1].display_conditions.create!(left_qing: form.c[0], op: "eq", value: "foo")
        form.c[1].update!(display_if: "all_met")
      end

      it "should render proper xml" do
        expect_xml(form, "grid_group_with_condition")
      end
    end

    context "multi-screen gridable" do
      let(:q1) { create(:question, qtype_name: "select_one") }
      let(:q2) { create(:question, qtype_name: "select_one", option_set: q1.option_set) }
      let(:form) do
        create(:form, :live, name: "Multi-screen Gridable", questions: [[q1, q2]])
      end

      before do
        form.sorted_children[0].update!(one_screen: false)
      end

      it "should not render with grid format" do
        expect_xml(form, "multi_screen_gridable")
      end
    end
  end

  describe "groups" do
    context "non-repeat group with condition on group" do
      let(:form) do
        create(:form, :live,
          name: "Non-repeat Group with Condition",
          question_types: ["text", %w[text text text]])
      end

      before do
        form.c[1].display_conditions.create!(left_qing: form.c[0], op: "eq", value: "foo")
        form.c[1].update!(display_if: "all_met")
      end

      it "should render proper xml" do
        expect_xml(form, "non_repeat_group_with_condition")
      end
    end

    context "single-screen repeat group with condition on question" do
      let(:form) do
        create(:form, :live,
          name: "Single-scrn Rpt Grp with Cond",
          question_types: [{repeating: {name: "Group A", items: %w[text text text]}}])
      end

      before do
        form.c[0].c[2].display_conditions.create!(left_qing: form.questionings.first, op: "eq", value: "foo")
        form.c[0].c[2].update!(display_if: "all_met")
      end

      it "should not render on single page due to condition" do
        expect_xml(form, "single_screen_repeat_group_with_condition")
      end
    end

    context "multi-screen group" do
      let(:form) do
        create(:form, :live, name: "Multi-screen Group", question_types: [%w[text text text]])
      end

      before do
        form.sorted_children[0].update!(one_screen: false)
      end

      it "should render proper xml" do
        expect_xml(form, "multi_screen_group")
      end
    end

    context "nested repeat group" do
      let(:form) do
        create(:form, :live,
          name: "Nested Repeat Group",
          question_types: [
            {repeating:
              {
                name: "Repeat Group 1",
                items:
                  ["text", # q1
                   "text", # q2
                   {
                     repeating:
                       {
                         name: "Repeat Group A",
                         items: %w[integer text] # q3, q4
                       }
                   },
                   "long_text"] # q5
              }},
            "text", # q6
            {
              repeating: {
                name: "Repeat Group 2",
                # Group as first question in parent group (this caused a bug at one time).
                items: [%w[text], "text", "text"] # q7, q8, q9
              }
            }
          ])
      end

      before do
        form.questioning_with_code("TextQ4").update!(default: "$TextQ2-$!RepeatNum")
        form.questioning_with_code("TextQ7").update!(default: "$TextQ2-$!RepeatNum")
      end

      it "should render proper xml" do
        expect_xml(form, "nested_repeat_group")
      end
    end

    context "empty group, hidden group, group with hidden question, group with only hidden question" do
      let!(:form) do
        create(:form, :live,
          name: "Empty and hidden",
          question_types: ["text",
                           {repeating: {name: "Repeat Group 1", items: []}},
                           {repeating: {name: "Repeat Group 2", items: %w[text text]}},
                           {repeating: {name: "Repeat Group 3", items: %w[text]}},
                           {repeating: {name: "Repeat Group 4", items: %w[text]}}])
      end

      before do
        form.c[2].c[0].update!(hidden: true, required: true)
        form.c[3].c[0].update!(hidden: true)
        form.c[4].update!(hidden: true)
      end

      it "should render proper xml" do
        expect_xml(form, "empty_and_hidden")
      end
    end

    context "empty group, disabled group, group with disabled question, group with only disabled question" do
      let!(:form) do
        create(:form, :live,
          name: "Empty and disabled",
          question_types: ["text",
                           {repeating: {name: "Repeat Group 1", items: []}},
                           {repeating: {name: "Repeat Group 2", items: %w[text text]}},
                           {repeating: {name: "Repeat Group 3", items: %w[text]}},
                           {repeating: {name: "Repeat Group 4", items: %w[text]}}])
      end

      before do
        form.c[2].c[0].update!(disabled: true, required: true)
        form.c[3].c[0].update!(disabled: true)
        form.c[4].update!(disabled: true)
      end

      it "should render proper xml" do
        expect_xml(form, "empty_and_disabled")
      end
    end
  end

  describe "multilevel selects" do
    context "various selects" do
      let(:form) do
        # 1-level, 2-level, 3-level; one at least one level required, one all levels required
        create(:form, :live,
          name: "Various Selects",
          question_types: %w[select_one multilevel_select_one super_multilevel_select_one])
      end

      before do
        form.c[1].update!(required: true)
        form.c[2].update!(required: true, all_levels_required: true)
      end

      it "should render proper xml" do
        expect_xml(form, "various_selects")
      end
    end

    # Tests that the single-screen group is correctly split to handle the
    # needs of the multi-level/cascading option set.
    context "non-repeat group with multilevel select" do
      let(:form) do
        create(:form, :live,
          name: "Non-repeat Group with Multilevel",
          question_types: [%w[text date multilevel_select_one integer]])
      end

      it "should render proper xml" do
        expect_xml(form, "non_repeat_group_with_multilevel_select")
      end
    end

    # Tests that the multi-screen group is correctly combined with the multi-screen needs of
    # of the multi-level/cascading option set.
    context "multiscreen group with multilevel select" do
      let(:form) do
        create(:form, :live,
          name: "Multi-screen Grp with Multilevel",
          question_types: [%w[text date multilevel_select_one integer]])
      end

      before do
        form.sorted_children[0].update!(one_screen: false)
      end

      it "should render proper xml" do
        expect_xml(form, "multiscreen_group_with_multilevel")
      end
    end

    # Tests that the single-screen inner repeat group is correctly split to handle the
    # needs of the multi-level/cascading option set, without disturbing the nested structure.
    context "nested group form with multilevel select" do
      let(:form) do
        create(:form, :live,
          name: "Nested Group with Multilevel",
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
        expect_xml(form, "nested_group_with_multilevel")
      end
    end

    context "small and large multilevel selects" do
      let(:form) do
        create(:form, :live,
          name: "Small and large multilevel",
          question_types: %w[multilevel_select_one super_multilevel_select_one])
      end
      let(:fixture_name) { "small_large_multilevel" }

      before do
        # Stub threshold constant so that first opt set is rendered normally,
        # second is rendered as external CSV.
        stub_const(ODK::OptionSetDecorator, "EXTERNAL_CSV_METHOD_THRESHOLD", 7)

        # Generate the itemset file and save with the saved fixture if saving fixtures.
        # Then if we do adb push tmp/odk/forms/small_large_multilevel/. /sdcard/odk/forms
        # it will copy the form and the required itemset file for testing.
        if save_fixtures
          itemsets_attachment = ODK::ItemsetsFormAttachment.new(form: form).tap(&:ensure_generated)
          media_dir = File.join(saved_fixture_dir(name: fixture_name, type: :form), "#{fixture_name}-media")
          FileUtils.mkdir_p(media_dir)
          puts "Saving itemsets file to #{media_dir}/itemsets.csv"
          FileUtils.mv(itemsets_attachment.priv_path, "#{media_dir}/itemsets.csv")
        end
      end

      it "should render proper xml" do
        expect_xml(form, fixture_name)
      end
    end
  end

  describe "dynamic patterns" do
    context "default response name and answer patterns" do
      let(:form) do
        create(:form, :live,
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
        expect_xml(form, "default_patterns")
      end
    end

    context "repeat group form with dynamic item names" do
      let!(:form) do
        create(:form, :live,
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
        expect_xml(form, "repeat_group")
      end
    end
  end

  describe "preload_last_saved" do
    let(:form) do
      create(:form, :live,
        name: "Preload Last Saved",
        question_types: %w[text text text])
    end

    before do
      form.c[1].update!(preload_last_saved: true)
    end

    it "should render proper xml" do
      expect_xml(form, "preload_last_saved")
    end
  end

  describe "media" do
    context "media questions" do
      let(:form) do
        create(:form, :live,
          name: "Media Questions",
          question_types: %w[text image annotated_image sketch signature audio video])
      end

      it "should render proper xml" do
        expect_xml(form, "media_questions")
      end
    end

    context "media prompts" do
      let(:form) { create(:form, :live, name: "Media Prompts", question_types: %w[text text text]) }

      before do
        form.c[0].question.media_prompt.attach(**attachment_args(audio_fixture("powerup.mp3")))
        form.c[1].question.media_prompt.attach(**attachment_args(video_fixture("jupiter.mp4")))
        form.c[2].question.media_prompt.attach(**attachment_args(image_fixture("the_swing.png")))
      end

      it "should render proper xml" do
        expect_xml(form, "media_prompts")
      end
    end
  end

  def expect_xml(form, fixture_name)
    do_request_and_expect_success
    expect(tidyxml(response.body)).to eq(prepare_odk_form_fixture(fixture_name, form))
  end

  def do_request_and_expect_success
    get(form_path(form, format: :xml))
    expect(response).to be_successful
  end

  def prepare_odk_form_fixture(name, form, options = {})
    prepare_odk_fixture(name: name, type: :form, form: form, **options)
  end
end
