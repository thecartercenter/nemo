require "spec_helper"

feature "remember context", js: true, sphinx: true do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:form) { create(:form) }
  let!(:responses) { create_list(:response, 1, form: form, user: other_user) }
  let!(:user_repsonses) { create_list(:response, 22, form: form, user: user) }

  scenario "remembers search and last page" do
    login(user)
    visit_responses
    perform_search
    visit_next_page
    view_response
    delete_response

    expect(page).to have_content displaying_responses_message(page: 2, total: 21)
  end
end

def visit_responses
  click_link("Responses")
  expect(page).to have_content displaying_responses_message(total: 23)
end

def perform_search
  fill_in "search", with: %(submitter:"#{user.name}")
  click_button("Search")
  expect(page).to have_content displaying_responses_message(total: 22)
end

def visit_next_page
  click_link "»"
  expect(page).to have_content displaying_responses_message(page: 2, total: 22)
end

def view_response
  first("tr.clickable").click
  expect(page).to have_content "Response: #"
end

def delete_response
  accept_alert do
    click_link "Delete Response"
  end
end

def displaying_responses_message(page: 1, per_page: 20, total: nil)
  raise "need to provide total" unless total
  start = (per_page * (page - 1)) + 1
  finish = [(per_page * page), total].min

  "Displaying Responses #{start} - #{finish} of #{total} in total"
end
