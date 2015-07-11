require "rails_helper"

RSpec.describe "Users" do
  describe "GET /users/sign_in" do
    attr_reader :user
    
    before do
      @user = create(:admin)
    end
    
    it "signs me in" do
      visit new_user_session_path
      fill_in 'user_email', :with => user.email
      fill_in 'Password', :with => 'password'
      click_button 'Log In'
    end
  end
end
