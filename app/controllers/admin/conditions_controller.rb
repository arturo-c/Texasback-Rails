class Admin::ConditionsController < ApplicationController
  layout 'admin'
  
  before_filter :load_lookups, :only => [ :new, :edit, :create, :update ]
  
  cache_sweeper :condition_sweeper, :only => [ :create, :update, :order ]
  
  def index
    @active_conditions = Condition.active
    @inactive_conditions = Condition.inactive
  end
  
  def show
    redirect_to edit_condition_path(params[:id])
  end
  
  def new
    @condition = Condition.new
    @version = ConditionVersion.new
  end
  
  def edit
    @condition = Condition.find(params[:id])
    
    if @condition.has_draft?
      @version = @condition.draft
    else
      @version = @condition.create_draft
    end
  end
  
  def create
    params[:condition][:draft_version_attributes][:images] ||= []
    
    @condition = Condition.new(params[:condition])    
    
    if @condition.save_with_draft
      flash[:notice] = 'This condition has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_condition_path(@condition)
      else
        redirect_to edit_condition_path(@condition)
      end
    else
      @version = @condition.draft
      
      render :action => 'new'
    end
  end
  
  def update
    @condition = Condition.find(params[:id])
    
    params[:condition][:draft_version_attributes][:images] ||= []
    
    if @condition.update_attributes_with_draft(params[:condition])
      if params[:save_and_preview]
        redirect_to preview_condition_path(@condition)
      elsif params[:revert_to_published] && @condition.has_published?
        @condition.draft.destroy
        
        flash[:notice] = "This condition's content has been reverted to the current published version."
        
        redirect_to edit_condition_path(@condition)
      elsif params[:publish] && @condition.has_draft?
        @condition.draft.publish
        
        flash[:notice] = "This condition has been published successfully."
        
        redirect_to edit_condition_path(@condition)
      else
        flash[:notice] = 'This condition has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_condition_path(@condition)
      end
    else
      @version = @condition.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This condition has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @condition = Condition.find(params[:id])
    
    @content_for_header_content = header_content_for_page('conditions')
    @content_for_body_class = "specific_conditions"
    
    @version = @condition.draft
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  # reorder the items
  def order
    if params[:conditions]
      conditions = params[:conditions].to_a
      
      start_index = params[:page].to_i
      
      conditions.each_with_index do |condition_id, index|
        condition = Condition.find(condition_id)
        
        condition.update_attributes(:display_order => (index + start_index))
      end
    end
    
    flash[:notice] = "The display order for the conditions has been updated."
    
    redirect_to conditions_path
  end
  
  protected
    def load_lookups
      @areas ||= Area.all
      @types ||= TreatmentType.top_level
    end
end
