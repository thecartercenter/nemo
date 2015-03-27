module FeatureSpecHelpers
  def login(user)
    visit "/test-login?user_id=#{user.id}"
    expect(page).to have_content("Profile:")
  end

  def fill_in_ckeditor(locator, opts)
    content = opts.fetch(:with).to_json
    page.execute_script <<-SCRIPT
      CKEDITOR.instances['#{locator}'].setData(#{content});
      $('textarea##{locator}').text(#{content});
    SCRIPT
  end
end