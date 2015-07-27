require "rails_helper"

RSpec.describe "ApplicationSettings" do
  after do
    ApplicationSetting.update_settings ApplicationSetting.defaults
    ApplicationSetting.apply!
  end

  context "for users" do
    before :each do 
      @user = create(:user)
      visit new_user_session_path
      fill_in 'Email', :with => @user.email
      fill_in 'Password', :with => @user.password
      click_button 'Log In'
    end

    it "applies application settings on every request" do
      old_password_archiving_count = Devise.password_archiving_count
      Devise.password_archiving_count = 5
    
      ApplicationSetting['devise.password_archiving_count'] = 10
    
      visit "/"
    
      expect(Devise.password_archiving_count).to equal 10
    
      Devise.password_archiving_count = old_password_archiving_count
    end
  
    it "only allows admins to access the application settings page" do
      visit application_settings_path
    
      expect(current_path).to_not equal application_settings_path
      expect(page).to have_content "You are not allowed to take the action you requested"
    end
  end
  
  context "for admin" do
    before :each do 
      @admin = create(:admin)
      visit new_user_session_path
      fill_in 'Email', :with => @admin.email
      fill_in 'Password', :with => @admin.password
      click_button 'Log In'
    end

    it "allows admins to view and edit application settings" do
      visit application_settings_path
      
      expect(page).to have_content "Expire password after"
      expect(page).to have_content "Password archive count"

      click_link "Edit Application Settings"
      
      fill_in "application_setting[devise.expire_password_after]", :with => "1"
      fill_in "application_setting[devise.password_archiving_count]", :with => "2"
      click_button "Submit"
  
      expect(page).to have_content "Application settings were successfully updated."
      expect(ApplicationSetting['devise.expire_password_after']).to equal 1.days.to_i
      expect(ApplicationSetting['devise.password_archiving_count']).to equal 2
    end
  end
end
