class ContactsController < ApplicationController
  layout 'radiant'
  
  #session :off
  
  before_filter :set_radiant_layout
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  def new
    @contact = Contact.new
  end
  
  def create
    @contact = Contact.new(params[:contact])
    
    
      if @contact.save
        ContactFormMailer.deliver_contact_form(@contact)

        flash[:contact_form] = @contact.id

        redirect_to contact_thanks_path
      else
        render :action => 'new'
      end
    
  end
  
  def thanks
    # intentionally blank
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @radiant_layout = "Default Layout"
    end
end
