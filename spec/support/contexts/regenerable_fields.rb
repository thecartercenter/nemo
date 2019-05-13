# frozen_string_literal: true

# Provides spec helper methods for dealing with regenerable fields.
shared_context "regenerable fields" do
  def expect_token_generated(class_name)
    within(class_name) do
      token = find(".regenerable-field span").text
      click_on("Generate")
      expect(page).to have_css(".fa-check-circle")
      expect(find(".regenerable-field span").text).not_to eq(token)
    end
  end

  def expect_token_regenerated(class_name)
    within(class_name) do
      token = find(".regenerable-field span").text
      accept_confirm { click_on("Regenerate") }
      expect(page).to have_css(".fa-check-circle")
      expect(find(".regenerable-field span").text).not_to eq(token)
    end
  end
end
