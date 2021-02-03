# frozen_string_literal: true

shared_context "file import" do
  def try_invalid_uploads_and_then(valid_upload_path)
    # Try hitting submit with no file, expect error
    yield if block_given?
    click_button("Import")
    expect(page).to have_content("No file selected for import.")

    # Invalid file
    yield if block_given?
    drop_in_dropzone(media_fixture("images/the_swing.jpg").path)
    expect_no_preview
    expect(page).to have_content("The uploaded file was not an accepted format.")
    expect(page).to have_button("Import")

    yield if block_given?
    drop_in_dropzone(valid_upload_path)
    expect_preview
    click_button("Import")
  end

  def run_scenario(node, correct_file, correct_file_name)
    # try hitting submit with no file, expect error
    click_button("Import")
    expect(page).to have_content("No file selected for import.")

    # invalid file
    drop_in_dropzone(invalid_file, 0)
    expect_no_preview(node)
    expect(page).to have_content("The uploaded file was not an accepted format.")
    expect(page).to have_button("Import")

    # try uploading valid file
    drop_in_dropzone(correct_file, 0)
    expect_preview(node)
    expect(page).to have_content(correct_file_name)
  end

  def drop_in_dropzone(file_path, index = 0)
    # Generate a fake input selector
    page.execute_script(<<-JS)
      fakeFileInput = window.$('<input/>').attr(
        {id: 'fakeFileInput', type:'file'}
      ).appendTo('#content');
    JS
    expect(page).to have_field("fakeFileInput")
    # Attach the file to the fake input selector with Capybara
    attach_file("fakeFileInput", file_path)
    # Trigger the fake drop event
    page.execute_script(<<-JS)
      var e = jQuery.Event('drop', { dataTransfer : { files : [fakeFileInput.get(0).files[0]] } });
      $('.dropzone')[#{index}].dropzone.listeners[0].events.drop(e);
    JS

    # If we don't wait for the upload to finish and another request is processed
    # in the meantime, it can lead to weird failures.
    wait_for_dropzone_upload

    page.execute_script(<<-JS)
      fakeFileInput.remove();
    JS
  end

  def expect_preview(node = page)
    expect(node).to have_selector(".dz-preview")
    expect(node).not_to have_content("The uploaded file was not an accepted format.")
  end

  def expect_no_preview(node = page)
    expect(node).not_to have_selector(".dz-preview")
  end

  def delete_file(node)
    node.find(".delete").click
    page.driver.browser.switch_to.alert.accept
  end

  private

  def wait_for_dropzone_upload
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until dropzone_ready?
    end
  end

  def dropzone_ready?
    page.evaluate_script("ELMO.fileUploaderManager.isUploading()")
  end
end
