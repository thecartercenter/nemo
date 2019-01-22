# frozen_string_literal: true

shared_context "batch delete" do

  shared_examples_for "select all on page" do |options|
    scenario do
      visit("/en/m/#{mission.compact_name}/#{options[:klass]}")
      search_for(options[:query]) unless options[:query].nil?
      click_on("Select All")
      click_on(options[:link])
      confirm_delete_msg = options[:num] == 1 ? "Are you sure you want to delete this #{options[:klass].singularize}?" :
        "Are you sure you want to delete these #{options[:num]} #{options[:klass]}?"
      expect(accept_alert).to eq(confirm_delete_msg)
      # For Users, you can't delete yourself, so result should be one less
      num_deleted = options[:query].nil? && options[:klass] == "users" ? options[:num] - 1 : options[:num]
      success_msg = options[:num] == 1 ? "1 #{options[:klass].singularize} deleted successfully" :
        "#{num_deleted} #{options[:klass]} deleted successfully"
      expect(page).to have_content(success_msg)
      expect(page).to have_content(preserved_obj) if preserved_obj.present?
    end
  end

  shared_examples_for "select nothing" do |klass, link|
    scenario do
      visit("/en/m/#{mission.compact_name}/#{klass}")
      click_on(link)
      expect(page).to have_content("You haven't selected anything")
    end
  end

  shared_examples_for "select all that exist" do |options|
    scenario do
      visit("/en/m/#{mission.compact_name}/#{options[:klass]}")
      search_for(options[:query]) unless options[:query].nil?
      click_on("Select All")
      click_on("Select all #{options[:num]} #{options[:klass].capitalize}")
      click_on(options[:link])
      expect(accept_alert).to eq("Are you sure you want to delete these #{options[:num]} #{options[:klass]}?")
      # For Users, you can't delete yourself, so result should be one less
      num_deleted = options[:query].nil? && options[:klass] == "users" ? options[:num] - 1 : options[:num]
      expect(page).to have_content("#{num_deleted} #{options[:klass]} deleted successfully")
    end
  end
end
