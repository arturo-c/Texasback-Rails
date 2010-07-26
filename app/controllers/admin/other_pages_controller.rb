class Admin::OtherPagesController < ApplicationController
  layout 'admin'  
  
  def index
    @active = OtherPage.all
  end
  
  def new
    @other_page = OtherPage.new
    @page = Page.new
    @page_version = PageVersion.new
  end
  
  def create
    @other_page = OtherPage.new
        
    if @other_page.create_new_page(params[:page], params[:page_version])
      if params[:save_and_preview]
        redirect_to preview_other_page_path(@other_page.id)
      else
        flash[:notice] = 'This page has been saved successfully. <a href="#" id="publish_link">Publish</a>'

        redirect_to edit_other_page_path(:id => @other_page.id)
      end
    else
      @page = @other_page.page
      @page_version = @other_page.version
      
      render :action => 'new'
    end
  end
  
  def edit
    @other_page = OtherPage.find(params[:id])    
    @page = @other_page.page    
    @page_version = @other_page.version
  end
  
  def update
    @other_page = OtherPage.find(params[:id])
    
    if @other_page.update_page(params[:page], params[:page_version])
      if params[:save_and_preview]
        redirect_to preview_other_page_path(@other_page.id)
      elsif params[:revert_to_published]
        if @other_page.version.draft?
          @other_page.version.destroy
        end
        
        flash[:notice] = 'This page has been reverted to the published version.'
        
        redirect_to edit_other_page_path(:id => @other_page.id)
      elsif params[:publish]
        unless @other_page.version.published?
          @other_page.version.publish
        end
        
        flash[:notice] = 'This page has been published successfully.'
        
        redirect_to edit_other_page_path(:id => @other_page.id)
      else        
        flash[:notice] = 'This page has been saved successfully. <a href="#" id="publish_link">Publish</a>' if @other_page.version.modified?
      
        redirect_to edit_other_page_path(:id => @other_page.id)
      end
    else
      @page = @other_page.page
      @page_version = @other_page.version
      
      render :action => 'edit'
    end
  end
  
  def preview
    @other_page = OtherPage.find(params[:id])    
    
    @page = @other_page.page
    @page_version = @other_page.version
    
    flash[:notice] = 'This page has been saved successfully. <a href="#" id="publish_link">Publish</a>' if @page_version.modified?
    
    # Setup preview content
    @content_for_title_tag = @page_version.page_title
    @content_for_header_content = @page_version.page.part_content :header_content
    @content_for_body_class = @page_version.page.part_content :body_class
    @content_for_secondary = @page_version.page.part_content :secondary
    @content_for_description = @page_version.meta_description
    @content_for_keywords = @page_version.meta_keywords
    
    # Use the default layout from Radiant instead of the admin view
    @radiant_layout = "Default Layout"
       
    render :layout => 'radiant'
  end
end
