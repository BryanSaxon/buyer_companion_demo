class ApplicationMailer < ActionMailer::Base
  default from: "Buyer Companion <noreply@#{Rails.application.credentials.app_host || 'example.com'}>"
  layout "mailer"
end
