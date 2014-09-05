module FeatureSpecHelpers
  def login(user)
    visit login_path(locale: 'en')
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
  end
end