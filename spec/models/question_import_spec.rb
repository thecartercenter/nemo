# frozen_string_literal: true

require "rails_helper"

# See also tabular_import_spec
describe Questions::Import do
  let(:mission) { get_mission }
  let(:mission_id) { mission.id }
  let(:file) { question_import_fixture(filename) }
  let(:import) { Questions::Import.new(mission_id: mission_id, file: file).tap(&:run) }
  let(:run_errors) { import.run_errors }
  let!(:yesno) { create(:option_set, name: "yesno", mission_id: mission_id) }

  context "with simple CSV file" do
    let(:filename) { "simple.csv" }

    it "should be able to import" do
      expect(import).to be_succeeded
      questions = import.questions
      expect(questions.count).to eq(3)
      expect(questions[0].code).to eq("localite")
      expect(questions[0].name_translations).to eq({
        "en" => "Select a location",
        "fr" => "Localité",
        "ht" => "lokalite"
      })
      expect(questions[1].qtype_name).to eq("select_one")
      expect(questions[2].hint_translations).to eq({
        "en" => "fish",
        "fr" => "poisson",
        "ht" => "poisson"
      })
      expect(questions[2].mission_id).to eq(mission_id)
    end
  end

  context "with no hints" do
    let(:filename) { "no_hints.csv" }

    it "should be able to import" do
      expect(import).to be_succeeded
      questions = import.questions
      expect(questions.count).to eq(3)
      expect(questions[0].hint_translations).to eq(nil)
      expect(questions[1].hint_translations).to eq({"fr" => "sûre", "ht" => "sor"})
    end
  end

  context "with non existent option set" do
    let(:filename) { "option_set_issues.csv" }

    it "should not be able to import" do
      expect(import).to_not(be_succeeded)
      expect(run_errors).to eq([
        "Row 2: Option set does not exist.",
        "Row 2: Option set: This field is required.",
        "Row 3: Option set: This field is required."
      ])
    end
  end

  context "with incorrect formats" do
    let(:filename) { "incorrect_formats.csv" }

    it "should not be able to import" do
      expect(import).to_not(be_succeeded)
      expect(run_errors).to eq([
        "Row 2: Code: Should start with a letter, use only letters and numbers, "\
          "and be a maximum of 20 characters.",
        "Row 3: Question type unrecognized."
      ])
    end
  end

  context "with missing required fields - code and option set" do
    let(:filename) { "missing_code.csv" }

    it "should not be able to import" do
      expect(import).to_not(be_succeeded)
      expect(run_errors).to eq(["Row 2: Question code is required.", "Row 3: Type: This field is required."])
    end
  end

  context "with missing titles" do
    let(:filename) { "missing_titles.csv" }

    it "should not be able to import" do
      expect(import).to_not(be_succeeded)
      expect(run_errors).to eq(["Row 2: You must enter a title in at least one language."])
    end
  end

  context "with missing column" do
    let(:filename) { "missing_column.csv" }

    it "should not be able to import" do
      expect(import).to_not(be_succeeded)
      expect(run_errors).to eq(["Your CSV was missing some columns, please see the template/docs."])
    end
  end
end
