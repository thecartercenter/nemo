# frozen_string_literal: true

require "rails_helper"
require "csv"

describe Forms::Export do
  let(:headers) do
    "Level,Type,Code,Prompt,Required?,Repeatable?,SkipLogic,Constraints,DisplayLogic," \
      "DisplayConditions,Default,Hidden\n"
  end

  context "simple form" do
    let(:simpleform) { create(:form, question_types: %w[text integer text]) }

    it "should produce the correct csv" do
      exporter = Forms::Export.new(simpleform)
      q1 = simpleform.questionings[0]
      q2 = simpleform.questionings[1]
      q3 = simpleform.questionings[2]
      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "2,integer,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "3,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n"
      )
    end

    it "should produce the correct xls" do
      qings = simpleform.questionings
      actual = write_and_open_xls(simpleform)

      # Dynamically generate substitutions based on the form fixture.
      # Form question names and codes will vary based on test run order.
      # Then, parse the resulting CSV, deleting the initial formatting character.

      # Prepare sheet 1 (questions).
      fixture_sheet1 = prepare_xlsform_fixture(
        "export_xls/basic_sheet1.csv",
        {label: qings.map(&:name), hint: qings.map(&:hint), name: qings.map(&:code)}
      )

      # Prepare sheet 2 (option sets, should be mostly blank so no substitutions needed).
      fixture_sheet2 = prepare_xlsform_fixture("export_xls/basic_sheet2.csv", {})

      # Prepare sheet 3 (form information).
      fixture_sheet3 = prepare_xlsform_fixture(
        "export_xls/basic_sheet3.csv",
        {title: [simpleform.name], id: [simpleform.id]}
      )

      # compare generated XLS with CSV fixtures for each sheet.
      matches_csv_fixture(actual.worksheet(0), fixture_sheet1)
      matches_csv_fixture(actual.worksheet(1), fixture_sheet2)
      matches_csv_fixture(actual.worksheet(2), fixture_sheet3)
    end
  end

  context "complex form" do
    let!(:form) do
      create(:form, :live, name: "Conditional Logic",
        question_types: ["text", "long_text", "integer", "decimal", "location",
                         "select_one", "multilevel_select_one",
                         "select_multiple", "datetime", "integer", "integer", {repeating: {items: [
                           "text",
                           %w[text text],
                           "text"
                         ]}}])
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

    it "should produce the correct xls" do
      actual = write_and_open_xls(form)

      qings = form.questionings
      groups = form.descendants.sort_by(&:full_dotted_rank).select { |child| child.type == "QingGroup" }

      # Prepend formatting character.
      actual.worksheet(0).row(0).first.prepend(UserFacingCSV::BOM)

      # Dynamically generate substitutions based on the form.
      # Form question names and codes will vary based on test run order.
      labels = qings.map(&:name)
      group_names = groups.map(&:group_name)
      # Option sets in the XLSForm are separated by underscores and will have the same name as the question label.
      # Not every qing has an associated option set, but this converts all question labels to have underscore separation
      # so that they can be easily accessed and substituted by the prepare_fixture method.
      option_set_labels = labels.map { |n| n.tr(" ", "_") }
      group_codes = group_names.map { |n| n.tr(" ", "_") }

      subs = {label: qings.map(&:name), hint: qings.map(&:hint), name: qings.map(&:code), os: option_set_labels,
              grouplabel: group_names, groupcode: group_codes, grouphint: groups.map(&:group_hint)}
      fixture = prepare_fixture("export_xls/complexform1_sheet1.csv", subs)
      fixture_parsed = CSV.parse(fixture)

      # compare generated XLS with CSV fixture.
      matches_csv_fixture(actual.worksheet(0), fixture_parsed)
    end
  end

  context "repeat group form with question outside repeat group before" do
    let(:repeatgroupform) do
      create(
        :form,
        question_types: ["text", "integer", {repeating: {items: %w[text text]}}]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(repeatgroupform)
      q1 = repeatgroupform.questionings[0]
      q2 = repeatgroupform.questionings[1]
      q31 = repeatgroupform.questionings[2]
      q32 = repeatgroupform.questionings[3]
      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "2,integer,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "3,,#{q31.parent.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n" \
        "3.1,text,#{q31.code},#{q31.name},false,true,\"\",\"\",always,\"\",,false\n" \
        "3.2,text,#{q32.code},#{q32.name},false,true,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "repeat group form with question outside repeat group after" do
    let(:repeatgroupform) do
      create(
        :form,
        question_types: [{repeating: {items: %w[text text]}}, "text"]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(repeatgroupform)
      q1 = repeatgroupform.questionings[0]
      q2 = repeatgroupform.questionings[1]
      q3 = repeatgroupform.questionings[2]
      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,,#{q1.parent.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n" \
        "1.1,text,#{q1.code},#{q1.name},false,true,\"\",\"\",always,\"\",,false\n" \
        "1.2,text,#{q2.code},#{q2.name},false,true,\"\",\"\",always,\"\",,false\n" \
        "2,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "regular group at start of form followed by a question outside of the group" do
    let(:groupform) do
      create(
        :form,
        question_types: [%w[text text], "integer"]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(groupform)

      q1 = groupform.questionings[0]
      q2 = groupform.questionings[1]
      q3 = groupform.questionings[2]

      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,,#{q1.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n" \
        "1.1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "1.2,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "2,integer,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "regular group at end of form preceded by a question outside the group" do
    let(:groupform) do
      create(
        :form,
        question_types: ["integer", %w[text text]]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(groupform)

      q1 = groupform.questionings[0]
      q2 = groupform.questionings[1]
      q3 = groupform.questionings[2]

      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,integer,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "2,,#{q2.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n" \
        "2.1,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "2.2,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "two groups in a row" do
    let(:groupform) do
      create(
        :form,
        question_types: [%w[text text], %w[text text]]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(groupform)

      q1 = groupform.questionings[0]
      q2 = groupform.questionings[1]
      q3 = groupform.questionings[2]
      q4 = groupform.questionings[3]

      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,,#{q1.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n" \
        "1.1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "1.2,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "2,,#{q3.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n" \
        "2.1,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "2.2,text,#{q4.code},#{q4.name},false,false,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "two repeat groups in a row" do
    let(:groupform) do
      create(
        :form,
        question_types: [{repeating: {items: %w[text text]}}, {repeating: {items: %w[text text]}}]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(groupform)
      q1 = groupform.questionings[0]
      q2 = groupform.questionings[1]
      q3 = groupform.questionings[2]
      q4 = groupform.questionings[3]

      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,,#{q1.parent.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n" \
        "1.1,text,#{q1.code},#{q1.name},false,true,\"\",\"\",always,\"\",,false\n" \
        "1.2,text,#{q2.code},#{q2.name},false,true,\"\",\"\",always,\"\",,false\n" \
        "2,,#{q3.parent.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n" \
        "2.1,text,#{q3.code},#{q3.name},false,true,\"\",\"\",always,\"\",,false\n" \
        "2.2,text,#{q4.code},#{q4.name},false,true,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "a group in a group" do
    let(:groupform) do
      create(
        :form,
        question_types: [["text", %w[text integer]]]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(groupform)
      q1 = groupform.questionings[0]
      q2 = groupform.questionings[1]
      q3 = groupform.questionings[2]

      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,,#{q1.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n" \
        "1.1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "1.2,,#{q2.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n" \
        "1.2.1,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "1.2.2,integer,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "skip logic form" do
    let!(:form) { create(:form, question_types: %w[text text text]) }
    let!(:skip_rule) { create(:skip_rule, source_item: form.c[1]) }

    it "should produce the correct csv" do
      exporter = Forms::Export.new(form)
      q1 = form.questionings[0]
      q2 = form.questionings[1]
      q3 = form.questionings[2]
      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "2,text,#{q2.code},#{q2.name},false,false,SKIP TO end of form,\"\",always,\"\",,false\n" \
        "3,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n"
      )
    end
  end

  context "repeat group of a group" do
    let(:groupform) do
      create(
        :form,
        question_types: [{repeating: {items: [%w[text text]]}}]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(groupform)
      g1 = groupform.preordered_items[0]
      g2 = groupform.preordered_items[1]
      q1 = groupform.preordered_items[2]
      q2 = groupform.preordered_items[3]

      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,,#{g1.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n" \
        "1.1,,#{g2.code},Group,false,false,\"\",\"\",always,\"\",,false\n" \
        "1.1.1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n" \
        "1.1.2,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "groups of repeat groups" do
    let(:groupform) do
      create(
        :form,
        question_types: [[{repeating: {items: %w[text text]}}]]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(groupform)
      g1 = groupform.preordered_items[0]
      g2 = groupform.preordered_items[1]
      q1 = groupform.preordered_items[2]
      q2 = groupform.preordered_items[3]

      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,,#{g1.code},Group,false,false,\"\",\"\",always,\"\",,false\n" \
        "1.1,,#{g2.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n" \
        "1.1.1,text,#{q1.code},#{q1.name},false,true,\"\",\"\",always,\"\",,false\n" \
        "1.1.2,text,#{q2.code},#{q2.name},false,true,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end

  context "repeat groups of repeat groups" do
    let(:groupform) do
      create(
        :form,
        question_types: [{repeating: {items: [{repeating: {items: %w[text text]}}]}}]
      )
    end

    it "should produce the correct csv" do
      exporter = Forms::Export.new(groupform)
      g1 = groupform.preordered_items[0]
      g2 = groupform.preordered_items[1]
      q1 = groupform.preordered_items[2]
      q2 = groupform.preordered_items[3]

      expect(exporter.to_csv).to eq(
        "#{headers}" \
        "1,,#{g1.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n" \
        "1.1,,#{g2.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n" \
        "1.1.1,text,#{q1.code},#{q1.name},false,true,\"\",\"\",always,\"\",,false\n" \
        "1.1.2,text,#{q2.code},#{q2.name},false,true,\"\",\"\",always,\"\",,false\n" \
      )
    end
  end
end

# Local helper method to check XLSForm output against a fixture row-by-row.
def matches_csv_fixture(actual, fixture)
  actual.each_with_index do |xls_row, row_index|
    expect(xls_row).to eq(fixture[row_index])
  end
end
