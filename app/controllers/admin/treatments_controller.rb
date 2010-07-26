class Admin::TreatmentsController < ApplicationController
  layout 'admin'
  
  before_filter :load_treatment_types, :except => [ :index ]
  
  cache_sweeper :treatment_sweeper, :only => [ :create, :update, :order ]
  
  def index
    if params[:type]
      @active_treatments = Treatment.active.by_type_or_parent params[:type]
    else
      @active_treatments = Treatment.active      
    end
    
    @inactive_treatments = Treatment.inactive
    
    @types = TreatmentType.all    
  end
  
  def new
    @treatment = Treatment.new
    @version = TreatmentVersion.new
  end
  
  def create
    @treatment = Treatment.new(params[:treatment])
    
    if @treatment.save_with_draft
      flash[:notice] = 'This treatment has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_treatment_path(@treatment)
      else
        redirect_to edit_treatment_path(@treatment)
      end
    else
      @version = @treatment.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @treatment = Treatment.find(params[:id])
    
    if @treatment.has_draft?
      @version = @treatment.draft
    else
      @version = @treatment.create_draft
    end
  end
  
  def update
    @treatment = Treatment.find(params[:id])
    
    if @treatment.update_attributes_with_draft(params[:treatment])
      if params[:save_and_preview]
        redirect_to preview_treatment_path(@treatment)
      elsif params[:revert_to_published] && @treatment.has_published?
        @treatment.draft.destroy
        
        flash[:notice] = "This treatment's content has been reverted to the current published version."
        
        redirect_to edit_treatment_path(@treatment)
      elsif params[:publish] && @treatment.has_draft?
        @treatment.draft.publish
        
        flash[:notice] = "This treatment has been published successfully."
        
        redirect_to edit_treatment_path(@treatment)
      else
        flash[:notice] = 'This treatment has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_treatment_path(@treatment)
      end
    else
      @version = @treatment.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This treatment has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @treatment = Treatment.find(params[:id])
    
    @content_for_header_content = '<img class="hero" src="/_images/hero_treatments.jpg" alt="Texas Back Institute offers a full range of services and treatments for back and neck pain. Our expert physicians will diagnose and care for back pain, lower back pain, spinal injury, bone defects and more." width="956" height="119" />'
    @content_for_body_class = "treatments surgical"
    
    @version = @treatment.draft
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @types = TreatmentType.top_level
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  # reorder the items
  def order
    if params[:treatments]
      treatments = params[:treatments].to_a
      
      treatments.each_with_index do |treatment_id, index|
        treatment = Treatment.find(treatment_id)
        
        treatment.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the treatments has been updated."
    
    if params[:type]
      redirect_to treatments_path(:type => params[:type])
    else
      redirect_to treatments_path
    end
  end
  
  protected
    def load_treatment_types
      @types = TreatmentType.top_level
    end
end
