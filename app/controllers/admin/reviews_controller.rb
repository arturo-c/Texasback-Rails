class Admin::ReviewsController < ApplicationController
  layout 'admin'  
  
  before_filter :load_lookups, :only => [ :index, :new, :create, :edit, :update ]
  
  cache_sweeper :review_sweeper, :only => [ :create, :update ]
  
  def index
    if params[:condition].to_i > 0
      @active = Review.find_all_with_condition(params[:condition]).paginate :page => params[:page], :per_page => 20
    else
      @active = Review.active.paginate :page => params[:page], :per_page => 20
    end    
    
    @inactive = Review.inactive        
    
    @no_conditions = Review.find_all_without_conditions
  end
  
  def new
    @review = Review.new
    @version = ReviewVersion.new
  end
  
  def create
    @review = Review.new(params[:review])
    
    if @review.save_with_draft
      flash[:notice] = 'This testimonial has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_testimonial_path(@review)
      else
        redirect_to edit_testimonial_path(@review)
      end
    else
      @version = @review.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @review = Review.find(params[:id])
    
    if @review.has_draft?
      @version = @review.draft
    else
      @version = @review.create_draft
    end
  end
  
  def update
    @review = Review.find(params[:id])
    
    params[:review][:condition_ids] ||= []
    params[:review][:treatment_ids] ||= []
    
    if @review.update_attributes_with_draft(params[:review])
      if params[:save_and_preview]
        redirect_to preview_testimonial_path(@review)
      elsif params[:revert_to_published] && @review.has_published?
        @review.draft.destroy
        
        flash[:notice] = "This testimonials's content has been reverted to the current published version."
        
        redirect_to edit_testimonial_path(@review)
      elsif params[:publish] && @review.has_draft?
        @review.draft.publish
        
        flash[:notice] = "This testimonial has been published successfully."
        
        redirect_to edit_testimonial_path(@review)
      else
        flash[:notice] = 'This testimonial has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_testimonial_path(@review)
      end
    else
      @version = @review.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This testimonial has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @review = Review.find(params[:id])
    
    @content_for_header_content = header_content_for_page('testimonials')
    @content_for_body_class = body_class_for_page('testimonials')
    
    @version = @review.draft
    
    @conditions = Condition.all_published
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  protected
    def load_lookups
      @conditions = Condition.all_published
      @types = TreatmentType.top_level
    end
end
