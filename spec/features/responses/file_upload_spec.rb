# frozen_string_literal: true

require "rails_helper"

feature "response form file upload", js: true do
  include_context "response tree"
  include_context "file import"

  let(:user) { create(:user) }
  let!(:form) { create(:form, :live, question_types: %w[image video]) }
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id} }

  before { login(user) }

  let(:image) { Rails.root.join("spec/fixtures/media/images/the_swing.jpg") }
  let(:image2) { Rails.root.join("spec/fixtures/media/images/the_swing.png") }
  let(:video) { Rails.root.join("spec/fixtures/media/video/jupiter.mp4") }
  let(:video2) { Rails.root.join("spec/fixtures/media/video/jupiter.avi") }

  scenario "uploading files" do
    visit new_response_path(params)

    image_node = find("[data-path='0']")
    video_node = find("[data-path='1']")

    # upload valid file
    drop_in_dropzone(image, 0)
    expect_preview(image_node)

    # try uploading invalid file
    drop_in_dropzone(image, 1)
    expect_no_preview(video_node)
    expect(video_node).to have_content("The uploaded file was not an accepted format.")

    # upload valid file
    drop_in_dropzone(video, 1)
    expect_preview(video_node)

    # save w/o user
    click_button("Save")
    expect(page).to have_content("Response is invalid")

    image_node = find("[data-path='0']")
    video_node = find("[data-path='1']")

    # thumbnails are still present
    expect(image_node).to have_selector(".media-thumbnail img")
    expect_thumbnail(image_node)
    expect(video_node).to have_selector(".media-thumbnail img")
    expect_thumbnail(video_node, placeholder: true)

    # media can be downloaded
    expect_download(image_node.find(".media-thumbnail .download")["href"])
    expect_download(video_node.find(".media-thumbnail .download")["href"])

    # upload different image
    delete_file(image_node)
    expect_no_preview(image_node)
    drop_in_dropzone(image2, 0)
    expect_preview(image_node)

    # delete video
    delete_file(video_node)
    expect_no_preview(video_node)

    # save w/ user
    select2(user.name, from: "response_user_id")
    click_button("Save")
    expect(page).to have_content("Response created successfully")

    response = Response.last
    visit edit_response_path(params.merge(id: response.shortcode))

    image_node = find("[data-path='0']")
    video_node = find("[data-path='1']")

    expect(image_node).to have_selector(".media-thumbnail img")
    expect(video_node).to_not(have_selector(".media-thumbnail img"))

    # delete image
    delete_file(image_node)
    expect_no_preview(image_node)

    # upload different video
    drop_in_dropzone(video2, 1)
    expect_preview(video_node)
    expect(page).to have_selector("#upload-progress-notice")
    expect(page).to_not(have_selector("#upload-progress-notice"))

    click_button("Save")
    expect(page).to have_content("Response updated successfully")

    visit edit_response_path(params.merge(id: response.shortcode))

    image_node = find("[data-path='0']")
    video_node = find("[data-path='1']")

    # no image thumbnail, video thumbnail present
    expect(image_node).to_not(have_selector(".media-thumbnail img"))
    expect(video_node).to have_selector(".media-thumbnail img")
  end

  def expect_download(url)
    res = Net::HTTP.get_response(URI(url))

    location = res["location"]
    if location
      warn("Redirected to #{location}")
      return expect_download(location)
    end

    expect(res.code).to eq("200")
  end

  def expect_thumbnail(node, placeholder: false)
    img = node.find(".media-thumbnail img")
    expect_download(img["src"])

    if placeholder
      expect(img["src"]).to match(/assets/)
    else
      expect(img["src"]).not_to match(/assets/)
    end
  end
end
