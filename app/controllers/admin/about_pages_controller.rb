class Admin::AboutPagesController < ApplicationController
  layout 'admin'
  
  cache_sweeper :about_sweeper, :only => [ :create, :update, :order ]
  
  def index
    @active = AboutPage.all
  end
  
  def show
    @about_page = AboutPage.find(params[:id])    
  end
  
  def new
    @about_page = AboutPage.new
    @page = Page.new
    @page_version = PageVersion.new
  end
  
  def create
    @about_page = AboutPage.new
        
    if @about_page.create_new_page(params[:page], params[:page_version])
      if params[:save_and_preview]
        redirect_to preview_about_page_path(@about_page.id)
      else
        flash[:notice] = 'This page has been saved successfully. <a href="#" id="publish_link">Publish</a>'

        redirect_to edit_about_page_path(:id => @about_page.id)
      end
    else
      @page = @about_page.page
      @page_version = @about_page.version
      
      render :action => 'new'
    end
  end
  
  def edit
    @about_page = AboutPage.find(params[:id])    
    @page = @about_page.page    
    @page_version = @about_page.version
  end
  
  def update
    @about_page = AboutPage.find(params[:id])
    
    if @about_page.update_page(params[:page], params[:page_version])
      if params[:save_and_preview]
        redirect_to preview_about_page_path(@about_page.id)
      elsif params[:revert_to_published]
        if @about_page.version.draft?
          @about_page.version.destroy
        end
        
        flash[:notice] = 'This page has been reverted to the published version.'
        
        redirect_to edit_about_page_path(:id => @about_page.id)
      elsif params[:publish]
        unless @about_page.version.published?
          @about_page.version.publish
        end
        
        flash[:notice] = 'This page has been published successfully.'
        
        redirect_to edit_about_page_path(:id => @about_page.id)
      else        
        flash[:notice] = 'This page has been saved successfully. <a href="#" id="publish_link">Publish</a>'
      
        redirect_to edit_about_page_path(:id => @about_page.id)
      end
    else
      @page = @about_page.page
      @page_version = @about_page.version
      
      render :action => 'edit'
    end
  end
  
  def order
    if params[:about_pages]
      items = params[:about_pages].to_a
      
      items.each_with_index do |id, index|
        item = AboutPage.find(id)
        
        item.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the pages has been updated."
    
    redirect_to about_pages_path
  end
  
  def preview
    flash[:notice] = 'This page has been saved successfully. <a href="#" id="publish_link">Publish</a>'
    
    @about_page = AboutPage.find(params[:id])    
    
    @page = @about_page.page
    @page_version = @about_page.version
    
    @about_pages = AboutPage.all
    
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
