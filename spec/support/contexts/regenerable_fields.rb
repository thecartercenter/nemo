# frozen_string_literal: true

# Provides spec helper methods for dealing with regenerable fields.
shared_context "regenerable fields" do
  def expect_token_regenerated(class_name, existing: true)
    within(class_name) do
      token = find(".regenerable-field span").text
      existing ? accept_confirm { click_on("Regenerate") } : click_on("Generate")
      expect(page).to have_css(".fa-check-circle")
      expect(find(".regenerable-field span").text).not_to eq(token)
    end
  end
end
