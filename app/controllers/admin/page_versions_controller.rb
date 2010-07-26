class Admin::PageVersionsController < ApplicationController
  layout 'admin'
  
  before_filter :load_or_create_version, :only => [ :new, :preview_slug, :preview_conditions, :preview_out_of_town, :preview_news_and_media ]
  
  def show
    flash.keep
    
    @page = Page.find_by_slug(params[:slug])
  rescue
    redirect_to admin_path
  end
    
  def new   
    flash.keep
    
    if params[:reset]
      flash[:notice] = "This page has been reverted to the published version."
    end
    
    if params[:publish]
      flash[:notice] = "This page has been published. Use the link below to view the page."
    end
    
    redirect_to edit_version_path(@draft_version.id)
  rescue
    redirect_to admin_path
  end
  
  def edit
    flash.keep
    
    @version = PageVersion.find(params[:id])
    
    unless @version.draft?
      redirect_to edit_content_path(:slug => @version.page.slug) 
    end
  end
  
  def update
    @version = PageVersion.find(params[:id])    
        
    if @version.update_attributes(params[:page_version])
      if params[:revert_to_published]
        slug = @version.page.slug

        if @version.draft?
          @version.destroy
        end

        redirect_to edit_content_path(:slug => slug, :reset => 'yes')
      elsif params[:publish]
        unless @version.published?
          @version.publish
        end

        # redirect to create another draft instead of loading this one again
        redirect_to edit_content_path(:slug => @version.page.slug, :publish => 'yes')
      elsif params[:save_and_preview]
        redirect_to preview_content_path(:slug => @version.page.slug)
      else
        if @version.modified?
          flash[:notice] = 'Page has been saved successfully. <a href="#" id="publish_link">Publish</a>'
        end
        
        redirect_to edit_version_path(params[:id])
      end
    else
      render :action => 'edit'
    end
  end
  
  def preview
    @version = PageVersion.find(params[:id])
    
    if @version.modified?
      flash[:notice] = 'Page has been saved successfully. <a href="#" id="publish_link">Publish</a>'
    end
    
    # Setup preview content
    @content_for_title_tag = @version.page_title
    @content_for_header_content = @version.page.part_content :header_content
    @content_for_body_class = @version.page.part_content :body_class
    @content_for_secondary = @version.page.part_content :secondary
    @content_for_description = @version.meta_description
    @content_for_keywords = @version.meta_keywords
    
    # Use the default layout from Radiant instead of the admin view
    @radiant_layout = "Default Layout"        
    render :layout => 'radiant'
  end
  
  # for some pages, show a custom preview, others just the default
  def preview_slug
    flash.keep
    
    redirect_to preview_version_path(:id => @draft_version.id)
  end
  
  def preview_conditions
    if @draft_version.modified?
      flash[:notice] = 'Page has been saved successfully. <a href="#" id="publish_link">Publish</a>'
    end
    
    @diagnostics_page = Page.find_by_url('/diagnostics', true)
    
    @diagnostics = Diagnostic.all_published    
    
    @content_for_title_tag = @draft_version.page_title
    @content_for_header_content = @draft_version.page.part_content :header_content
    @content_for_body_class = "specific_conditions"
    @content_for_secondary = @draft_version.page.part_content :secondary
    @content_for_description = @draft_version.meta_description
    @content_for_keywords = @draft_version.meta_keywords
    
    # Use the default layout from Radiant instead of the admin view
    @radiant_layout = "Default Layout"        
    render :layout => 'radiant'
  end
  
  def preview_out_of_town
    if @draft_version.modified?
      flash[:notice] = 'Page has been saved successfully. <a href="#" id="publish_link">Publish</a>'
    end
    
   # Setup preview content
    @content_for_title_tag = @draft_version.page_title
    @content_for_header_content = @draft_version.page.part_content :header_content
    @content_for_body_class = @draft_version.page.part_content :body_class
    @content_for_secondary = @draft_version.page.part_content :secondary
    @content_for_description = @draft_version.meta_description
    @content_for_keywords = @draft_version.meta_keywords
    
    @preferred_hotels = Hotel.preferred
    @other_hotels = Hotel.not_preferred
    
    # Use the default layout from Radiant instead of the admin view
    @radiant_layout = "Default Layout"        
    render :layout => 'radiant'
  end
  
  def preview_news_and_media
    if @draft_version.modified?
      flash[:notice] = 'Page has been saved successfully. <a href="#" id="publish_link">Publish</a>'
    end
    
   # Setup preview content
    @content_for_title_tag = @draft_version.page_title
    @content_for_header_content = @draft_version.page.part_content :header_content
    @content_for_body_class = @draft_version.page.part_content :body_class
    @content_for_secondary = @draft_version.page.part_content :secondary
    @content_for_description = @draft_version.meta_description
    @content_for_keywords = @draft_version.meta_keywords
    
    @releases = PressRelease.active
    @about_pages = AboutPage.all
    @media_entries = MediaEntry.active
    
    # Use the default layout from Radiant instead of the admin view
    @radiant_layout = "Default Layout"        
    render :layout => 'radiant'
  end
  
  protected
    def load_or_create_version
      @draft_version = PageVersion.find_draft_for_slug(params[:slug])

      unless @draft_version
        @draft_version = PageVersion.create_for_slug(params[:slug])
      end
    end   
end
