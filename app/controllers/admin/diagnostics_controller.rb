class Admin::DiagnosticsController < ApplicationController
  layout 'admin'
  
  cache_sweeper :diagnostic_sweeper, :only => [ :create, :update, :order ]
  
  def index
    @active_diagnostics = Diagnostic.active
    @inactive_diagnostics = Diagnostic.inactive
  end
  
  def new
    @diagnostic = Diagnostic.new
    @version = DiagnosticVersion.new
  end
  
  def create
    @diagnostic = Diagnostic.new(params[:diagnostic])
    
    if @diagnostic.save_with_draft
      flash[:notice] = 'This diagnostic has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_diagnostic_path(@diagnostic)
      else
        redirect_to edit_diagnostic_path(@diagnostic)
      end
    else
      @version = @diagnostic.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @diagnostic = Diagnostic.find(params[:id])
    
    if @diagnostic.has_draft?
      @version = @diagnostic.draft
    else
      @version = @diagnostic.create_draft
    end
  end
  
  def update
    @diagnostic = Diagnostic.find(params[:id])
    
    @diagnostic.create_draft unless @diagnostic.has_draft?
    
    @diagnostic.attributes = params[:diagnostic]
    
    @changed = @diagnostic.changed? or @diagnostic.draft.changed?

    if @diagnostic.update_attributes_with_draft(params[:diagnostic])
      if params[:save_and_preview]
        redirect_to preview_diagnostic_path(@diagnostic)
      elsif params[:revert_to_published] && @diagnostic.has_published?
        @diagnostic.draft.destroy
        
        flash[:notice] = "This diagnostic's content has been reverted to the current published version."
        
        redirect_to edit_diagnostic_path(@diagnostic)
      elsif params[:publish] && @diagnostic.has_draft?
        @diagnostic.draft.publish
        
        flash[:notice] = "This diagnostic has been published successfully."
        
        redirect_to edit_diagnostic_path(@diagnostic)
      else
        if @diagnostic.draft.modified? or @changed
          flash[:notice] = 'This diagnostic has been saved. <a href="#" id="publish_link">Publish</a>'
        end
        
        redirect_to edit_diagnostic_path(@diagnostic)
      end
    else
      @version = @diagnostic.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    @diagnostic = Diagnostic.find(params[:id])
    
    @content_for_header_content = header_content_for_page('conditions')
    @content_for_body_class = body_class_for_page('conditions')
        
    @version = @diagnostic.draft
    
    if @version.modified?
      flash[:notice] = 'This diagnostic has been saved. <a href="#" id="publish_link">Publish</a>'
    end
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @diagnostics = Diagnostic.all_published
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  # reorder the items
  def order
    if params[:diagnostics]
      diagnostics = params[:diagnostics].to_a
      
      diagnostics.each_with_index do |diagnostic_id, index|
        diagnostic = Diagnostic.find(diagnostic_id)
        
        diagnostic.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the diagnostics has been updated."
    
    if params[:type]
      redirect_to diagnostics_path(:type => params[:type])
    else
      redirect_to diagnostics_path
    end
  end
  
  def edit_content
    @version = load_page_version
  end
  
  def update_content
    @version = load_page_version
          
    if @version.update_attributes(params[:page_version])
      if params[:revert_to_published]
        if @version.draft?
          @version.destroy
        end
          
        flash[:notice] = "This content has been reverted to the published version."
        
        redirect_to edit_content_diagnostics_path
      elsif params[:publish]
        unless @version.published?
          @version.publish
        end

        flash[:notice] = "This content has been published. Use the links below to view the content."
        
        redirect_to edit_content_diagnostics_path
      elsif params[:save_and_preview]
        if @version.modified?
          flash[:notice] = 'Diagnostics introduction has been saved successfully. <a href="#" id="publish_link">Publish</a>'
        end
        
        redirect_to preview_content_diagnostics_path
      else
        if @version.modified?
          flash[:notice] = 'Diagnostics introduction has been saved successfully. <a href="#" id="publish_link">Publish</a>'
        end
        
        redirect_to edit_content_diagnostics_path
      end
    else
      render :action => 'edit_content'
    end
  end
  
  def preview_content
    flash.keep
    
    @conditions_page = Page.find_by_url('/conditions', true)

    @version = load_page_version
    
    @diagnostics = Diagnostic.all_published    
    
    @content_for_header_content = header_content_for_page('conditions')
    @content_for_body_class = "specific_conditions"
    @content_for_title_tag = title_tag_for_page('conditions')
    
    # Use the default layout from Radiant instead of the admin view
    @radiant_layout = "Default Layout"        
    render :layout => 'radiant'
  end
  
  protected
    def load_page_version
      version = PageVersion.find_draft_for_slug('diagnostics')

      unless version
        version = PageVersion.create_for_slug('diagnostics')
      end
      
      version
    end
end
