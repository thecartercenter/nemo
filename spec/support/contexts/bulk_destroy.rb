# frozen_string_literal: true

shared_context "bulk destroy" do
  shared_examples_for "select all on page" do |options|
    scenario do
      prev_count = klass.count
      plural_name = klass.model_name.plural
      singular_name = klass.model_name.singular
      visit("/en/m/#{mission.compact_name}/#{plural_name}")
      search_for(options[:query]) unless options[:query].nil?
      click_on("Select All")

      if options[:uncheck_one]
        checkboxes = all(".cb_col input")
        checkboxes[checkboxes.size / 2].click
      end

      click_on(delete_link_name)
      confirm_delete_msg =
        if options[:expect_to_delete] == 1
          "Are you sure you want to delete this #{singular_name}?"
        else
          "Are you sure you want to delete these #{options[:expect_to_delete]} #{plural_name}?"
        end
      expect(accept_alert).to eq(confirm_delete_msg)

      # For Users, you can't delete yourself, so result should be one less
      options[:expect_to_delete] -= 1 if options[:query].nil? && klass == User
      noun = singular_name.pluralize(options[:expect_to_delete])
      success_msg = "#{options[:expect_to_delete]} #{noun} deleted successfully"
      expect(page).to have_content(success_msg)
      expect(page).to have_content(preserved_obj) if preserved_obj.present?
      expect(prev_count - klass.count).to eq(options[:expect_to_delete])
    end
  end

  shared_examples_for "select nothing" do
    scenario do
      plural_name = klass.model_name.plural
      visit("/en/m/#{mission.compact_name}/#{plural_name}")
      click_on(delete_link_name)
      expect(page).to have_content("You haven't selected anything")
    end
  end

  shared_examples_for "select all that exist" do |options|
    scenario do
      prev_count = klass.count
      plural_name = klass.model_name.plural
      visit("/en/m/#{mission.compact_name}/#{plural_name}")
      search_for(options[:query]) unless options[:query].nil?
      click_on("Select All")
      find("a", text: /Select all \d+ #{plural_name.capitalize}/).click

      if options[:uncheck_one]
        checkboxes = all(".cb_col input")
        checkboxes[checkboxes.size / 2].click
        expect(page).not_to have_css(".alert", text: "are selected")
      end

      click_on(delete_link_name)
      expect(accept_alert).to eq("Are you sure you want to delete these "\
        "#{options[:expect_to_delete]} #{plural_name}?")

      # For Users, you can't delete yourself, so result should be one less
      options[:expect_to_delete] -= 1 if options[:query].nil? && klass == User
      expect(page).to have_content(/#{options[:expect_to_delete]} #{plural_name}? deleted successfully/)
      expect(prev_count - klass.count).to eq(options[:expect_to_delete])
    end
  end
end
