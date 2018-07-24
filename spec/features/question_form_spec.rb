require "rails_helper"

describe "question form" do
  let!(:mission) { get_mission }
  let!(:user) { create(:admin, role_name: "coordinator") }

  before do
    login(user)
  end

  EXPECTED_FIELDS = {
    "Text" => %i(key),
    "Long Text" => %i(key),
    "Integer" => %i(key min max),
    "Counter" => %i(key autoinc),
    "Decimal" => %i(key min max),
    "Location"  => %i(key),
    "Select One"  => %i(key optset),
    "Select Multiple" => %i(key optset),
    "Date/Time" => %i(key metadata),
    "Date"  => %i(key),
    "Time"  => %i(key),
    "Image" => %i(),
    "Annotated Image" => %i(),
    "Signature" => %i(),
    "Sketch"  => %i(),
    "Audio" => %i(),
    "Video" => %i()
  }

  FIELD_NAMES = {
    key: "Is Key Question?",
    optset: "Option Set",
    min: "Minimum",
    max: "Maximum",
    autoinc: "Auto Increment Counter?",
    metadata: "Metadata Type"
  }

  scenario "correct fields show for various question types", js: true do
    visit new_question_path(locale: "en", mode: "m", mission_name: mission.compact_name)
    fill_in "Code", with: "AQuestion"

    EXPECTED_FIELDS.each do |type, fields|
      select type, from: "* Type"
      fields.each do |k|
        expect(page).to have_css("label", text: FIELD_NAMES[k]), "#{type} should have #{k}"
      end
      (FIELD_NAMES.keys - fields).each do |k|
        expect(page).not_to have_css("label", text: FIELD_NAMES[k]), "#{type} should not have #{k}"
      end
    end
  end

  scenario "audio upload works", js: true do
    visit new_question_path(locale: "en", mode: "m", mission_name: mission.compact_name)
    fill_in "Code", with: "AQuestion"
    fill_in "Title", with: "Jay's"
    select "Text", from: "Type"

    attach_file("Audio Prompt", audio_fixture("powerup.mp3").path)
    click_on "Save"

    visit question_path(
      locale: "en",
      mode: "m",
      mission_name: mission.compact_name,
      id: Question.last.id
    )

    expect(page).to have_content("powerup.mp3")

    # edit view shows file name
    click_on "Edit Question"
    expect(page).to have_content("powerup.mp3")

    # editing an audio prompt works
    attach_file("Audio Prompt", audio_fixture("powerup.wav").path)
    click_on "Save"

    # and still allows you change the audio prompt file
    visit edit_question_path(
      Question.last.id,
      locale: "en",
      mode: "m",
      mission_name: get_mission.compact_name
    )
    expect(page).to have_css("input#question_audio_prompt")
    expect(page).to have_content("powerup.wav")
    expect(page).not_to have_content("powerup.mp3")
  end
end
