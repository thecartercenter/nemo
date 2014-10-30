module FeatureSpecHelpers
  def login(user)
    visit login_path(locale: 'en')
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
  end

  def fill_in_ckeditor(locator, opts)
    content = opts.fetch(:with).to_json
    page.execute_script <<-SCRIPT
      CKEDITOR.instances['#{locator}'].setData(#{content});
      $('textarea##{locator}').text(#{content});
    SCRIPT
  end
end