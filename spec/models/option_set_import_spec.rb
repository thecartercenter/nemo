# frozen_string_literal: true

require "rails_helper"

describe OptionSets::Import do
  let(:mission) { get_mission }
  let(:mission_id) { mission.id }
  let(:file) { option_set_import_fixture(filename) }
  let(:import) { OptionSets::Import.new(mission_id: mission_id, name: "MySet", file: file).tap(&:run) }
  let(:run_errors) { import.run_errors }

  context "with simple XLSX file" do
    let(:filename) { "simple.xlsx" }

    context "in mission mode" do
      it "should succeed" do
        expect_simple_option_set(import, mission: mission)
      end
    end

    context "in admin mode" do
      let(:mission_id) { nil }

      it "should be able to import an option set in admin mode" do
        expect_simple_option_set(import, mission: nil)
      end
    end
  end

  context "with simple CSV file" do
    let(:filename) { "simple.csv" }

    it "should successfully import csv option set" do
      expect_simple_option_set(import, mission: mission)
    end
  end

  context "multi-level geographic" do
    let(:filename) { "multilevel_geographic.xlsx" }

    it "should be able to import a multi-level geographic option set" do
      expect(import).to be_succeeded
      option_set = import.option_set

      expect(option_set).to have_attributes(
        level_count: 3,
        geographic?: true,
        allow_coordinates?: true
      )

      expect(option_set.level_names).to start_with(
        {"en" => "Province"},
        {"en" => "City/District"},
        "en" => "Commune/Territory"
      )

      # check the total and top-level option counts
      expect(option_set.total_options).to eq(321)
      expect(option_set.options).to have(26).items

      # make sure that the non-leaf options have no coordinates
      option_set.preordered_option_nodes.each do |node|
        if node.child_options.present?
          expect(node).to have_attributes(option: have_attributes(coordinates?: false))
        end
      end

      # verify the latitude and longitude of one of the options
      expect(option_set.all_options).to include(
        have_attributes(canonical_name: "Aketi", latitude: 2.739529, longitude: 23.780851)
      )
    end
  end

  context "with invalid file type" do
    let(:filename) { "not_tabular.jpg" }

    it "should correctly report error" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq(["The uploaded file must be a valid XLSX-type Excel file."])
    end
  end

  context "with older XLS file" do
    let(:filename) { "old_format.xls" }

    it "should correctly report error" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq(["The uploaded file must be a valid XLSX-type Excel file."])
    end
  end

  context "with invalid coordinates" do
    let(:filename) { "invalid_geographic.xlsx" }

    it "should correctly report errors" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq([
        "Row 8: Latitude: must be less than or equal to 90",
        "Row 15: Coordinates: The provided coordinates are not valid."
      ])
    end
  end

  context "with blank interior cells" do
    let(:filename) { "blank_interior.xlsx" }

    it "should correctly report errors" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq([
        "Error on row 36: blank interior cell.",
        "Error on row 51: blank interior cell."
      ])
    end
  end

  context "with no data rows" do
    let(:filename) { "no_rows.xlsx" }

    it "should correctly report errors" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq(["No rows to import."])
    end
  end

  context "with long strings" do
    let(:filename) { "long_strings.xlsx" }

    it "should correctly report errors" do
      expect(import).not_to be_succeeded
      expect(run_errors).to eq([
        "Error on row 1: headers can't be more than 20 characters.",
        "Error on row 10: options can't be more than 255 characters."
      ])
    end
  end

  private

  def expect_simple_option_set(import, mission:)
    expect(import).to be_succeeded

    option_set = import.option_set
    expect(option_set).to have_attributes(name: "MySet", geographic?: false, mission: mission)
    expect(option_set.levels).to be_nil
    expect(option_set.level_names).to include("en" => "Province")
    expect(option_set.total_options).to eq(26)
    expect(option_set.all_options).to include(have_attributes(canonical_name: "Kinshasa"))
  end
end
