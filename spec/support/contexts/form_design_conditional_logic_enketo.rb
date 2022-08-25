# frozen_string_literal: true

shared_context "form design conditional logic for Enketo" do
  def fill_in_value(value)
    # Deal with weird Capybara behavior: unset the value before resetting.
    find('input[name*="/data/qing"]').set("")
    find('input[name*="/data/qing"]').native.send_keys(value)
    blur
  end

  def expect_filled_in_value(value)
    input = find('input[name*="/data/qing"]')
    expect(page).to have_field(input[:name], with: value)
  end

  # Click the save button without waiting for any loading afterward
  # (unreliable unless you know there will be validation errors instead of a redirect).
  def save_only
    blur
    find("#enketo-submit").click
  end

  # Allow processing time for AJAX because it doesn't behave well with Capybara.
  def save_and_wait
    save_only
    wait_for_load
  end

  # Trigger a JS blur event, e.g. to make sure the form performs validation logic.
  def blur
    page.document.find("body").click
  end
end
