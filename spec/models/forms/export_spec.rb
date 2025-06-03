# frozen_string_literal: true

require "rails_helper"
require "csv"

describe Forms::Export do
  let(:headers) do
    "Level,Type,Code,Prompt,Required?,Repeatable?,SkipLogic,Constraints,DisplayLogic,"\
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
        "#{headers}"\
        "1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "2,integer,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "3,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n"
      )
    end

    it "should produce the correct xls" do
      exporter = Forms::Export.new(simpleform)

      # Write xls file using to_xls method
      # need "wb" option to write a binary file
      File.open("tmp/simpleform.xls", "wb") { |f| f.write exporter.to_xls }

      actual = Spreadsheet.open "tmp/simpleform.xls"

      subs = { label: ["Text Question Title 12", "Integer Question Title 13", "Text Question Title 14"], hint: ["Question Hint 12", "Question Hint 13", "Question Hint 14"], name: ["TextQ12", "IntegerQ13", "TextQ14"] }

      fixture = prepare_fixture("export_xls/basic_sheet1.csv", subs)

      fixture_parsed = CSV.parse(fixture)

      # write to csv
      actual.worksheet(0).each_with_index do |xls_row, row_index|
        expect(xls_row).to match(fixture_parsed[row_index])
      end

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
        "#{headers}"\
        "1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "2,integer,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "3,,#{q31.parent.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n"\
        "3.1,text,#{q31.code},#{q31.name},false,true,\"\",\"\",always,\"\",,false\n"\
        "3.2,text,#{q32.code},#{q32.name},false,true,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,,#{q1.parent.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n"\
        "1.1,text,#{q1.code},#{q1.name},false,true,\"\",\"\",always,\"\",,false\n"\
        "1.2,text,#{q2.code},#{q2.name},false,true,\"\",\"\",always,\"\",,false\n"\
        "2,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,,#{q1.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n"\
        "1.1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "1.2,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "2,integer,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,integer,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "2,,#{q2.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n"\
        "2.1,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "2.2,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,,#{q1.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n"\
        "1.1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "1.2,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "2,,#{q3.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n"\
        "2.1,text,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "2.2,text,#{q4.code},#{q4.name},false,false,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,,#{q1.parent.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n"\
        "1.1,text,#{q1.code},#{q1.name},false,true,\"\",\"\",always,\"\",,false\n"\
        "1.2,text,#{q2.code},#{q2.name},false,true,\"\",\"\",always,\"\",,false\n"\
        "2,,#{q3.parent.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n"\
        "2.1,text,#{q3.code},#{q3.name},false,true,\"\",\"\",always,\"\",,false\n"\
        "2.2,text,#{q4.code},#{q4.name},false,true,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,,#{q1.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n"\
        "1.1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "1.2,,#{q2.parent.code},Group,false,false,\"\",\"\",always,\"\",,false\n"\
        "1.2.1,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "1.2.2,integer,#{q3.code},#{q3.name},false,false,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "2,text,#{q2.code},#{q2.name},false,false,SKIP TO end of form,\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,,#{g1.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n"\
        "1.1,,#{g2.code},Group,false,false,\"\",\"\",always,\"\",,false\n"\
        "1.1.1,text,#{q1.code},#{q1.name},false,false,\"\",\"\",always,\"\",,false\n"\
        "1.1.2,text,#{q2.code},#{q2.name},false,false,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,,#{g1.code},Group,false,false,\"\",\"\",always,\"\",,false\n"\
        "1.1,,#{g2.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n"\
        "1.1.1,text,#{q1.code},#{q1.name},false,true,\"\",\"\",always,\"\",,false\n"\
        "1.1.2,text,#{q2.code},#{q2.name},false,true,\"\",\"\",always,\"\",,false\n"\
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
        "#{headers}"\
        "1,,#{g1.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n"\
        "1.1,,#{g2.code},Repeat Group,false,true,\"\",\"\",always,\"\",,false\n"\
        "1.1.1,text,#{q1.code},#{q1.name},false,true,\"\",\"\",always,\"\",,false\n"\
        "1.1.2,text,#{q2.code},#{q2.name},false,true,\"\",\"\",always,\"\",,false\n"\
      )
    end
  end
end
