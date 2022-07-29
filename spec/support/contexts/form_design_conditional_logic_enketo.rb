# frozen_string_literal: true

shared_context "form design conditional logic for Enketo" do
  def fill_in_value(value)
    # Deal with weird Capybara behavior: unset the value before resetting.
    find('input[name*="/data/qing"]').set("")
    find('input[name*="/data/qing"]').set(value)
  end

  def expect_filled_in_value(value)
    input = find('input[name*="/data/qing"]')
    expect(page).to have_field(input[:name], with: value)
  end
end
