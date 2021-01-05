# frozen_string_literal: true

require "rails_helper"

feature "user form password field" do
  let(:mission) { get_mission }

  before { login(actor) }

  shared_examples("edit methods that should work online and offline") do
    scenario "leaving password unchanged should work" do
      visit(url)
      expect(page).to have_content("No change")
      select("No change", from: "user_reset_password_method")
      click_button("Save")
      expect(page).to have_content("updated successfully")
    end

    scenario "generating new password should work" do
      visit(url)
      expect(page).to have_content("Generate a new password and show printable login instructions")
      select("Generate a new password and show printable login instructions",
        from: "user_reset_password_method")
      click_button("Save")
      expect(page).to have_content("Login Instructions")
    end

    scenario "entering new password should work" do
      visit(url)
      expect(page).to have_content("Enter a new password")
      select("Enter a new password", from: "user_reset_password_method")
      fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
      fill_in("Retype Password", with: "n3wP*ssword", match: :prefer_exact)
      click_button("Save")
      expect(page).to have_content("updated successfully")
    end

    scenario "entering invalid password shows validation errors" do
      visit(url)
      select("Enter a new password", from: "user_reset_password_method")
      fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
      fill_in("Retype Password", with: "", match: :prefer_exact)
      click_button("Save")
      expect(page).to have_content("User is invalid")
      expect(page).to have_content("doesn't match Password")
    end

    scenario "entering new password with instructions should work" do
      visit(url)
      expect(page).to have_content("Enter a new password and show printable login instructions")
      select("Enter a new password and show printable login instructions",
        from: "user_reset_password_method")
      fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
      fill_in("Retype Password", with: "n3wP*ssword", match: :prefer_exact)
      click_button("Save")
      expect(page).to have_content("Login Instructions")
    end

    scenario "entering invalid password shows validation errors" do
      visit(url)
      select("Enter a new password and show printable login instructions",
        from: "user_reset_password_method")
      fill_in("Password", with: "n3wP*ssword", match: :prefer_exact)
      fill_in("Retype Password", with: "", match: :prefer_exact)
      click_button("Save")
      expect(page).to have_content("User is invalid")
      expect(page).to have_content("doesn't match Password")
    end
  end

  shared_examples("editing in online and offline mode") do
    context "online mode" do
      include_examples("edit methods that should work online and offline")

      scenario "sending password reset instructions via email should work" do
        visit(url)
        expect(page).to have_content("Send password reset instructions via email")
        select("Send password reset instructions via email", from: "user_reset_password_method")
        expect { click_button("Save") }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(page).to have_content("updated successfully")
      end
    end

    context "offline mode" do
      around do |example|
        ENV["NEMO_OFFLINE_MODE"] = "true"
        example.run
        ENV["NEMO_OFFLINE_MODE"] = "false"
      end

      include_examples("edit methods that should work online and offline")

      scenario do
        visit(url)
        expect(page).to_not(have_content("Send password reset instructions via email"))
      end
    end
  end

  context "as admin" do
    let(:actor) { create(:admin, mission: mission) }

    context "creating user" do
      context "online mode" do
        scenario "setting enumerator password via printable should be unavailable in admin mode" do
          visit "/en/admin/users/new"
          expect(page).to have_content("Send password reset instructions via email")
          expect(page).not_to have_content("Generate a new password and show printable login instructions")
        end
      end

      context "offline mode" do
        around do |example|
          ENV["NEMO_OFFLINE_MODE"] = "true"
          example.run
          ENV["NEMO_OFFLINE_MODE"] = "false"
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
    end
  end

  context "as coordinator" do
    let(:actor) { create(:user, role_name: :coordinator, mission: mission) }

    context "creating user" do
      context "online mode" do
        scenario "setting enumerator password via email should work" do
          visit "/en/m/#{mission.compact_name}/users/new"
          expect(page).to have_content("Send password reset instructions via email")
          expect(page).to have_content("Generate a new password and show printable login instructions")
          fill_out_form
          select("Send password reset instructions via email", from: "user_reset_password_method")
          expect { click_button("Save") }.to change { ActionMailer::Base.deliveries.count }.by(1)
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
      end

      context "offline mode" do
        around do |example|
          ENV["NEMO_OFFLINE_MODE"] = "true"
          example.run
          ENV["NEMO_OFFLINE_MODE"] = "false"
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
      end
    end

    context "editing user in mission mode" do
      let(:url) { "/en/m/#{mission.compact_name}/users/#{target_user.id}/edit" }

      context "acting on enumerator" do
        let(:target_user) { create(:user, role_name: :enumerator) }
        include_examples("editing in online and offline mode")
      end
    end
  end

  context "as enumerator" do
    let(:actor) { create(:user, role_name: :enumerator, mission: mission) }

    context "editing user in mission mode" do
      let(:url) { "/en/m/#{mission.compact_name}/users/#{target_user.id}/edit" }

      context "acting on self" do
        let(:target_user) { actor }
        include_examples("editing in online and offline mode")
      end

      context "acting on other enumerator" do
        let(:target_user) { create(:user, role_name: :enumerator) }

        scenario "should be forbidden" do
          visit(url)
          expect(page).to have_content("Unauthorized")
        end
      end
    end
  end

  def fill_out_form(role: "Enumerator", email: true, admin: false)
    fill_in("* Full Name", with: "Foo")
    fill_in("* Username", with: "foo")
    select(role, from: "user_assignments_attributes_0_role") unless role.nil?
    fill_in("Email", with: "foo@bar.com") if email
    check("Is Admin?") if admin
  end
end
