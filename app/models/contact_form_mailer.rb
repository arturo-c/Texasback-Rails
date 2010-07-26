class ContactFormMailer < ActionMailer::Base
  def contact_form(contact)
    recipients CONFIG['contact_form_recipients']
    #bcc "jdtornow@gmail.com"
    from "noreply@texasback.com"
    subject "Texas Back Institute Contact Form Submission"
    body :contact => contact
  end
  
  def doctor_question(entry)
    recipients CONFIG['ask_the_doctor_recipients']
    #bcc "jdtornow@gmail.com"
    from "noreply@texasback.com"
    subject "Texas Back Institute Ask the Doctor Submission"
    body :entry => entry
  end
  
  def email_friend(my_name, my_email, friend_name, friend_email, link)
    recipients friend_email
    #bcc "jdtornow@gmail.com"
    from my_email
    subject "Texas Back Institute Link"
    body :my_name => my_name, :my_email => my_email, :friend_name => friend_name, :friend_email => friend_email, :link => link
  end
end