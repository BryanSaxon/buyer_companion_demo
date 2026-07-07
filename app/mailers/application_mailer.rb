class ApplicationMailer < ActionMailer::Base
  default from: "Buyer Companion <#{Rails.application.credentials.dig(:notifications, :email) || 'noreply@example.com'}>"
  layout "mailer"
end
