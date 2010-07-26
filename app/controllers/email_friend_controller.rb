class EmailFriendController < ApplicationController
  layout 'popup'
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  def index
    # nothing
    
    @title = "Email a Friend"
  end

  def send_email
    @condition = Condition.find_by_slug(params[:slug])
    
    @friend_emails = params[:friend_emails].to_a
    @friend_names = params[:friend_names].to_a
    @my_name = params[:my_name]
    @my_email = params[:my_email]
    
    @friend_emails.each_with_index do |email, index|
      if is_valid_email(email)
        ContactFormMailer.deliver_email_friend(@my_name, @my_email, @friend_names[index], email, url_for(view_condition_url(:slug => @condition.slug)))
      end
    end
    
    redirect_to email_friend_thanks_path(:slug => @condition.slug)
  end

  def thanks
    @title = "Email a Friend"
  end
  
  protected
    def is_valid_email(email)
      email =~ /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/
    end
end
