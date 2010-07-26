class Admin::AppointmentsPageController < ApplicationController
  layout 'admin'
  
  before_filter :load_page, :except => :index
  
  def index
    # blank
  end
  
  def edit
    
  end
  
  def update      
    if @version.update_attributes(params[:page_version])
      if params[:revert_to_published]
        if @version.draft?
          @version.destroy
        end

        flash[:notice] = "This page has been reverted to the published version"

        redirect_to edit_appointments_path
      elsif params[:publish]
        unless @version.published?
          @version.publish
        end
        
        flash[:notice] = "This page has been published"
        
        redirect_to edit_appointments_path
      elsif params[:save_and_preview]
        redirect_to preview_appointments_path
      else
        flash[:notice] = 'Page has been saved successfully. <a href="#" id="publish_link">Publish</a>' if @version.modified?
        
        redirect_to edit_appointments_path
      end
    else
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'Page has been saved successfully. <a href="#" id="publish_link">Publish</a>' if @version.modified?
    
    # Setup preview content
    @content_for_title_tag = @version.page_title
    @content_for_header_content = @page.part_content :header_content
    @content_for_body_class = @page.part_content :body_class
    @content_for_secondary = @version.secondary
    @content_for_description = @version.meta_description
    @content_for_keywords = @version.meta_keywords
    
    # Use the default layout from Radiant instead of the admin view
    @radiant_layout = "Default Layout"
         
    render :layout => 'radiant'
  end
  
  protected
    def load_page
      @page = Page.find_by_slug('appointments')
      
      @version = PageVersion.find_draft_for_page(@page)

      unless @version
        @version = PageVersion.create_draft_for_page(@page)
      end
    end
end
