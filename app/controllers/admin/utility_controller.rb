class Admin::UtilityController < ApplicationController
  layout 'admin'
  
  def home    
    @conditions = Condition.not_published
    @treatments = Treatment.not_published
    @testimonials = Review.not_published
  end
  
  # Landing page for editing the locations section content
  def locations
    # blank
  end
  
  # Landing page for editing history content
  def history
    # blank
  end
  
  # Landing page for editing careers content
  def careers
    # blank
  end
  
  # Landing page for editing medical fellowships content
  def medical_fellowships
    # blank
  end
  
  # Landing page for editing disclosue of interests content
  def disclosure_of_interests
    # blank
  end  
  
  # Landing page for editing news and media content
  def news_and_media
    # blank
  end
  
  # Landing page for editing patient forms content
  def patient_forms
    # blank
  end
  
  # export results to excel
  def contacts_export    
    @from = DateTime.new(params[:contacts_export]["from(1i)"].to_i, params[:contacts_export]["from(2i)"].to_i, params[:contacts_export]["from(3i)"].to_i)
    @to = DateTime.new(params[:contacts_export]["to(1i)"].to_i, params[:contacts_export]["to(2i)"].to_i, params[:contacts_export]["to(3i)"].to_i, 23, 59, 59)
    
    @entries = Contact.find(:all, :conditions => [ "created_at >= ? AND created_at <= ?", @from, @to ])
    
    respond_to do |format|
      format.xls # export.xls.erb
    end
  #rescue
   # redirect_to admin_path
  end
end
