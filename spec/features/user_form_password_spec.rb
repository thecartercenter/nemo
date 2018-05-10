require "spec_helper"

feature "user form password field" do
  let(:mission) { get_mission }

  before do
    login(actor)
  end

  context "user editing profile" do
    let(:actor) { create(:user) }

    scenario "typing password while editing profile" do
      visit "/en/users/#{actor.id}/edit"
      fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
      fill_in("Retype Password", with: "n3wP*ssword", match: :prefer_exact)
      click_button("Save")
      expect(page).to have_content("Profile updated successfully.")
    end
  end

  context "admin" do
    let(:actor) { create(:admin, mission: mission) }

    context "creating user" do
      context "normal mode" do
        scenario "setting enumerator password via email should work" do
          visit "/en/m/#{mission.compact_name}/users/new"
          expect(page).to have_content("Send password reset instructions via email")
          expect(page).to have_content("Generate a new password and show printable login instructions")
          fill_out_form
          select("Send password reset instructions via email", from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("User created successfully")
        end

        scenario "setting enumerator password via email without email should fail" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form(email: false)
          select("Send password reset instructions via email", from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("you didn't specify an email")
        end

        scenario "setting enumerator password via printable should work" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form
          select("Generate a new password and show printable login instructions", from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end

        scenario "setting coordinator password via printable should error" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form(role: "Coordinator")
          select("Generate a new password and show printable login instructions", from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("Printed instructions are only available to enumerators.")
        end

        scenario "setting enumerator password via printable should be unavailable in admin mode" do
          visit "/en/admin/users/new"
          expect(page).to have_content("Send password reset instructions via email")
          expect(page).not_to have_content("Generate a new password and show printable login instructions")
        end
      end

      context "offline mode" do
        around do |example|
          configatron.offline_mode = true
          example.run
          configatron.offline_mode = false
        end

        scenario "setting enumerator password via email should be unavailable" do
          visit "/en/m/#{mission.compact_name}/users/new"
          expect(page).to have_content("Generate a new password and show printable login instructions")
          expect(page).not_to have_content("Send password reset instructions via email")
        end

        scenario "setting coordinator password via printable should work" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form(role: "Coordinator")
          select("Generate a new password and show printable login instructions", from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end

        scenario "setting enumerator password via printable should work in admin mode" do
          visit "/en/admin/users/new"
          expect(page).to have_content("Generate a new password and show printable login instructions")
          expect(page).not_to have_content("Send password reset instructions via email")
          fill_out_form(role: nil, admin: true)
          select("Generate a new password and show printable login instructions", from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end
      end

      def fill_out_form(role: "Enumerator", email: true, admin: false)
        fill_in("* Full Name", with: "Foo")
        fill_in("* Username", with: "foo")
        select role, from: "user_assignments_attributes_0_role" unless role.nil?
        fill_in("Email", with: "foo@bar.com") if email
        check("Is Admin?") if admin
      end
    end

    context "editing user" do
      let(:enumerator) { create(:user, role_name: :enumerator, mission: mission) }
      let(:coordinator) { create(:user, role_name: :coordinator, mission: mission) }

      scenario "resetting enumerator password via email should work" do
        visit "/en/m/#{mission.compact_name}/users/#{enumerator.id}/edit"
        expect(page).to have_content("Send password reset instructions via email")
        expect(page).to have_content("Generate a new password and show printable login instructions")
        select("Generate a new password and show printable login instructions", from: "user_reset_password_method")
        click_button("Save")
        expect(page).to have_content("User updated successfully")
      end

      scenario "resetting enumerator password via printable should work" do
        visit "/en/m/#{mission.compact_name}/users/#{enumerator.id}/edit"
        select("Generate a new password and show printable login instructions", from: "user_reset_password_method")
        click_button("Save")
        expect(page).to have_content("Login Instructions")
      end

      scenario "resetting coordinator password via printable should not be available" do
        visit "/en/m/#{mission.compact_name}/users/#{coordinator.id}/edit"
        expect(page).to have_content("Send password reset instructions via email")
        expect(page).not_to have_content("Generate a new password and show printable login instructions")
      end
    end
  end
end

feature "login instructions" do
  let(:enumerator) { create(:user, role_name: :enumerator, mission: mission) }
  let(:mission) { get_mission }
  let(:actor) { create(:admin, mission: mission) }

  before do
    login(actor)
  end

  scenario "printable instructions do not mask password", js: true do
    visit "/en/m/#{mission.compact_name}/users/#{enumerator.id}/login-instructions?password=testpass&medium=print"
    expect(page).to have_content("Login Instructions")
    expect(page).to have_content("testpass")
    expect(evaluate_script("$('.unmasked').is(':visible')")).to eq true
  end
end
