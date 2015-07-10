
ActionMailer::Base.smtp_settings = {
  :address              => ENV['SMTP_MAIL_ADDR'],
  :port                 => ENV['SMTP_MAIL_PORT'],
  :domain               => ENV['SMTP_MAIL_DOMAIN'],
  :user_name            => ENV['SMTP_MAIL_USER_NAME'],
  :password             => ENV['SMTP_MAIL_PASSWORD'],
  :authentication       => 'plain',
  :enable_starttls_auto => 'true'
}
