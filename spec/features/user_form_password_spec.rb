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
        scenario "setting observer password via email should work" do
          visit "/en/m/#{mission.compact_name}/users/new"
          expect(page).to have_content("Send email instructions")
          expect(page).to have_content("Show printable instructions")
          fill_out_form
          choose("Send email instructions")
          click_button("Save")
          expect(page).to have_content("User created successfully")
        end

        scenario "setting observer password via email without email should fail" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form(email: false)
          choose("Send email instructions")
          click_button("Save")
          expect(page).to have_content("you didn't specify an email")
        end

        scenario "setting observer password via printable should work" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form
          choose("Show printable instructions")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end

        scenario "setting coordinator password via printable should error" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form(role: "Coordinator")
          choose("Show printable instructions")
          click_button("Save")
          expect(page).to have_content("Printed instructions are only available to observers.")
        end

        scenario "setting observer password via printable should be unavailable in admin mode" do
          visit "/en/admin/users/new"
          expect(page).to have_content("Send email instructions")
          expect(page).not_to have_content("Show printable instructions")
        end
      end

      context "offline mode" do
        around do |example|
          configatron.offline_mode = true
          example.run
          configatron.offline_mode = false
        end

        scenario "setting observer password via email should be unavailable" do
          visit "/en/m/#{mission.compact_name}/users/new"
          expect(page).to have_content("Show printable instructions")
          expect(page).not_to have_content("Send email instructions")
        end

        scenario "setting coordinator password via printable should work" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form(role: "Coordinator")
          choose("Show printable instructions")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end

        scenario "setting observer password via printable should work in admin mode" do
          visit "/en/admin/users/new"
          expect(page).to have_content("Show printable instructions")
          expect(page).not_to have_content("Send email instructions")
          fill_out_form(role: nil, admin: true)
          choose("Show printable instructions")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end
      end

      def fill_out_form(role: "Observer", email: true, admin: false)
        fill_in("* Full Name", with: "Foo")
        fill_in("* Username", with: "foo")
        select role, from: "user_assignments_attributes_0_role" unless role.nil?
        fill_in("Email", with: "foo@bar.com") if email
        check("Is Administrator?") if admin
      end
    end

    context "editing user" do
      let(:observer) { create(:user, role_name: :observer, mission: mission) }
      let(:coordinator) { create(:user, role_name: :coordinator, mission: mission) }

      scenario "resetting observer password via email should work" do
        visit "/en/m/#{mission.compact_name}/users/#{observer.id}/edit"
        expect(page).to have_content("Reset password and send email instructions")
        expect(page).to have_content("Reset password and show printable instructions")
        choose("Reset password and send email instructions")
        click_button("Save")
        expect(page).to have_content("User updated successfully")
      end

      scenario "resetting observer password via printable should work" do
        visit "/en/m/#{mission.compact_name}/users/#{observer.id}/edit"
        choose("Reset password and show printable instructions")
        click_button("Save")
        expect(page).to have_content("Login Instructions")
      end

      scenario "resetting coordinator password via printable should not be available" do
        visit "/en/m/#{mission.compact_name}/users/#{coordinator.id}/edit"
        expect(page).to have_content("Reset password and send email instructions")
        expect(page).not_to have_content("Reset password and show printable instructions")
      end
    end
  end
end
