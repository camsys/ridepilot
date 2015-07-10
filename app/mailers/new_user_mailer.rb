class NewUserMailer < ActionMailer::Base
  default :from => ENV['SYSTEM_SEND_FROM_ADDRESS']
  
  def new_user_email(user, password)
    @user     = user
    @password = password
    @url      = edit_user_password_url :reset_password_token => user.reset_password_token, :initial => true
    mail(:to => user.email,  :subject => "Welcome to RidePilot")
 end


end
