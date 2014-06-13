require 'spec_helper'

describe 'path helpers' do
  before do
    @user = FactoryGirl.create(:user, :admin => true)
    @mission = FactoryGirl.create(:mission, :name => 'Foo')
    login(@user)
  end

  context 'in basic mode' do
    before do
      get('/en/route-tests')
    end

    it 'should be correct' do
      expect_urls "
        /en/users/#{@user.id}/edit
        /en/logged-out
        /en
        /fr
        /en/m/foo
        /en/admin
        /en/admin/forms
        /en/m/foo/forms"
    end
  end

  context 'in mission mode' do
    before do
      get("/en/m/foo/route-tests")
    end

    it 'should be correct' do
      expect_urls "
        /en/users/#{@user.id}/edit
        /en/logged-out
        /en
        /fr
        /en/m/foo
        /en/admin
        /en/admin/forms
        /en/m/foo/forms"
    end
  end

  context 'in admin mode' do
    before do
      get("/en/admin/route-tests")
    end

    it 'should be correct' do
      expect_urls "
        /en/users/#{@user.id}/edit
        /en/logged-out
        /en
        /fr
        /en/m/foo
        /en/admin
        /en/m/foo/forms
        /en/admin/forms"
    end
  end


  def expect_urls(urls)
    expect(response.body).to eq urls.gsub(/( )+/, '').strip + "\n"
  end
end
