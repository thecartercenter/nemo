# frozen_string_literal: true

require "rails_helper"

describe "question form", js: true do
  let!(:mission) { get_mission }
  let!(:user) { create(:admin, role_name: "coordinator") }

  before do
    login(user)
  end

  EXPECTED_FIELDS = {
    "Text" => %i[key],
    "Long Text" => %i[key],
    "Integer" => %i[key min max],
    "Counter" => %i[key autoinc],
    "Decimal" => %i[key min max],
    "Location" => %i[key],
    "Select One" => %i[key optset],
    "Select Multiple" => %i[key optset],
    "Date/Time" => %i[key metadata],
    "Date" => %i[key],
    "Time" => %i[key],
    "Image" => %i[],
    "Annotated Image" => %i[],
    "Signature" => %i[],
    "Sketch" => %i[],
    "Audio" => %i[],
    "Video" => %i[]
  }.freeze

  FIELD_NAMES = {
    key: "Is Key Question?",
    optset: "Option Set",
    min: "Minimum",
    max: "Maximum",
    autoinc: "Auto Increment Counter?",
    metadata: "Metadata Type"
  }.freeze

  scenario "correct fields show for various question types" do
    visit(new_question_path(locale: "en", mode: "m", mission_name: mission.compact_name))
    fill_in("Code", with: "AQuestion")

    EXPECTED_FIELDS.each do |type, fields|
      select(type, from: "* Type")
      fields.each do |k|
        expect(page).to have_css("label", text: FIELD_NAMES[k]), "#{type} should have #{k}"
      end
      (FIELD_NAMES.keys - fields).each do |k|
        expect(page).not_to have_css("label", text: FIELD_NAMES[k]), "#{type} should not have #{k}"
      end
    end
  end

  scenario "adding option set works" do
    visit(new_question_path(locale: "en", mode: "m", mission_name: mission.compact_name))
    select("Select One", from: "Type")

    click_link("Create Option Set")
    within("#create-option-set.modal") do
      fill_in("Name", with: "Flat")
      click_link("Add Option")
      fill_in("English", with: "One")
      click_button("Save and Add Another")
      expect(page).to have_field("English", with: "")
      fill_in("English", with: "Two")
      click_button("Save and Close")
      click_button("Save")
    end

    expect(page).to have_select("Option Set", selected: "Flat")
  end

  scenario "audio upload works" do
    visit(new_question_path(locale: "en", mode: "m", mission_name: mission.compact_name))
    fill_in("Code", with: "AQuestion")
    fill_in("Title", with: "Jay's")
    select("Text", from: "Type")

    attach_file("Media Prompt", audio_fixture("powerup.mp3").path)
    click_on("Save")

    visit(question_path(locale: "en", mode: "m", mission_name: mission.compact_name, id: Question.last.id))
    expect(page).to have_content(".mp3")

    # Edit view shows file name and allows edit
    click_on("Edit")
    expect(page).to have_content(".mp3")
    attach_file("Media Prompt", audio_fixture("powerup.wav").path)
    click_on("Save")

    # and still allows you change the media prompt file
    visit(edit_question_path(Question.last.id, locale: "en", mode: "m",
                                               mission_name: get_mission.compact_name))
    expect(page).to have_css("input#question_media_prompt")
    expect(page).to have_content(".wav")
    expect(page).not_to have_content(".mp3")
  end

  scenario "tags are deduplicated" do
    visit(new_question_path(locale: "en", mode: "m", mission_name: mission.compact_name))

    fill_in("token-input-question_tag_ids", with: "foo")
    expect(page).to have_content("Searching...")

    # wait for search to complete, then click token
    expect(page).not_to have_content("Searching...")
    all(".token-input-dropdown-elmo li").first.click

    # token was added
    tokens = all("li.token-input-token-elmo")
    expect(tokens.size).to eq(1)
    expect(tokens.first).to have_content("foo")

    fill_in("token-input-question_tag_ids", with: "foo")
    expect(page).to have_content("Searching...")

    # wait for search to complete, then click token
    expect(page).not_to have_content("Searching...")
    all(".token-input-dropdown-elmo li").first.click

    # no new token was added
    tokens = all("li.token-input-token-elmo")
    expect(tokens.size).to eq(1)
    expect(tokens.first).to have_content("foo")
  end
end
