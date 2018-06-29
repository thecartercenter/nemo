require "rails_helper"

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
          expect { click_button("Save") }.to change { ActionMailer::Base.deliveries.count }.by 1
          expect(page).to have_content("User created successfully")
        end

        scenario "setting enumerator password via email without email should fail" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form(email: false)
          select("Send password reset instructions via email", from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("Not allowed unless an email address is provided")
        end

        scenario "setting enumerator password via printable should work" do
          visit "/en/m/#{mission.compact_name}/users/new"
          fill_out_form
          select("Generate a new password and show printable login instructions",
            from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
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
          select("Generate a new password and show printable login instructions",
            from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end

        scenario "setting enumerator password via printable should work in admin mode" do
          visit "/en/admin/users/new"
          expect(page).to have_content("Generate a new password and show printable login instructions")
          expect(page).not_to have_content("Send password reset instructions via email")
          fill_out_form(role: nil, admin: true)
          select("Generate a new password and show printable login instructions",
            from: "user_reset_password_method")
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
      before { visit "/en/m/#{mission.compact_name}/users/#{user.id}/edit" }

      shared_examples "leaving password unchanged" do
        scenario "leaving password unchanged should work" do
          expect(page).to have_content("No change")
          select("No change", from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("updated successfully")
        end
      end

      shared_examples "sending password instructions via email" do
        scenario "sending password reset instructions via email should work" do
          expect(page).to have_content("Send password reset instructions via email")
          select("Send password reset instructions via email", from: "user_reset_password_method")
          expect { click_button("Save") }.to change { ActionMailer::Base.deliveries.count }.by 1
          expect(page).to have_content("updated successfully")
        end
      end

      shared_examples "generating new password" do
        scenario "generating new password should work" do
          expect(page).to have_content("Generate a new password and show printable login  instructions")
          select("Generate a new password and show printable login instructions",
            from: "user_reset_password_method")
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end
      end

      shared_examples "entering new password" do
        scenario "entering new password should work" do
          expect(page).to have_content("Enter a new password")
          select("Enter a new password", from: "user_reset_password_method")
          fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
          fill_in("Retype Password", with: "n3wP*ssword", match: :prefer_exact)
          click_button("Save")
          expect(page).to have_content("updated successfully")
        end

        context "invalid password" do
          scenario "entering invalid password shows validation errors" do
            select("Enter a new password", from: "user_reset_password_method")
            fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
            fill_in("Retype Password", with: "", match: :prefer_exact)
            click_button("Save")
            expect(page).to have_content("User is invalid")
            expect(page).to have_content("doesn't match Password")
          end
        end
      end

      shared_examples "entering new password with login instructions" do
        scenario "entering new password with instructions should work" do
          expect(page).to have_content("Enter a new password and show printable login instructions")
          select("Enter a new password and show printable login instructions",
            from: "user_reset_password_method")
          fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
          fill_in("Retype Password", with: "n3wP*ssword", match: :prefer_exact)
          click_button("Save")
          expect(page).to have_content("Login Instructions")
        end

        context "invalid password" do
          scenario "entering invalid password shows validation errors" do
            select("Enter a new password and show printable login instructions",
              from: "user_reset_password_method")
            fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
            fill_in("Retype Password", with: "", match: :prefer_exact)
            click_button("Save")
            expect(page).to have_content("User is invalid")
            expect(page).to have_content("doesn't match Password")
          end
        end
      end

      shared_examples "offline" do
        around do |example|
          configatron.offline_mode = true
          example.run
          configatron.offline_mode = false
        end

        it { expect(page).to_not have_content("Send password reset instructions via email") }
      end

      context "self" do
        let(:user) { actor }

        include_examples("leaving password unchanged")
        include_examples("sending password instructions via email")
        include_examples("entering new password")
        include_examples("entering new password with login instructions")

        context "offline" do
          include_examples("offline")
          include_examples("leaving password unchanged")
          include_examples("entering new password")
          include_examples("entering new password with login instructions")
        end
      end

      context "enumerator" do
        let(:user) { create(:user, role_name: :enumerator, mission: mission) }

        include_examples("leaving password unchanged")
        include_examples("sending password instructions via email")
        include_examples("generating new password")
        include_examples("entering new password with login instructions")

        context "offline" do
          include_examples("offline")
          include_examples("leaving password unchanged")
          include_examples("generating new password")
          include_examples("entering new password")
        end
      end

      context "coordinator" do
        let(:user) { create(:user, role_name: :coordinator, mission: mission) }

        include_examples("leaving password unchanged")
        include_examples("sending password instructions via email")
        include_examples("entering new password")

        context "offline" do
          include_examples("offline")
          include_examples("leaving password unchanged")
          include_examples("generating new password")
          include_examples("entering new password")
        end
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
    query = "password=testpass&medium=print"
    visit "/en/m/#{mission.compact_name}/users/#{enumerator.id}/login-instructions?#{query}"
    expect(page).to have_content("Login Instructions")
    expect(page).to have_content("testpass")
    expect(evaluate_script("$('.unmasked').is(':visible')")).to eq true
  end
end
