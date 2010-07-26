class Admin::AbstractsController < ApplicationController
  layout 'admin'  
  
  before_filter :load_lookups, :only => [ :index, :new, :create, :edit, :update ]
  
  cache_sweeper :abstract_sweeper, :only => [ :create, :update, :order ]
  
  def index
    if params[:year].to_i > 0 || params[:topic].to_i > 0
      @active = Abstract.find_all_with_topic_and_year(params[:topic], params[:year]).paginate :page => params[:page], :per_page => 20
    else
      @active = Abstract.active.paginate :page => params[:page], :per_page => 20
    end
    
    @inactive = Abstract.inactive 
    @years = Abstract.all.collect(&:publish_year).uniq.sort.reverse
    
    @no_topics = Abstract.find_all_without_topics
  end
  
  def show
    redirect_to edit_abstract_path(params[:id])
  end
  
  def new
    @abstract = Abstract.new :publish_date => Date.today, :link => 'http://'
    @version = AbstractVersion.new
  end
  
  def create
    @abstract = Abstract.new(params[:abstract])
    
    if @abstract.save_with_draft
      flash[:notice] = 'This abstract has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_abstract_path(@abstract)
      else
        redirect_to edit_abstract_path(@abstract)
      end
    else
      @version = @abstract.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @abstract = Abstract.find(params[:id])
    
    if @abstract.has_draft?
      @version = @abstract.draft
    else
      @version = @abstract.create_draft
    end
  end
  
  def update
    @abstract = Abstract.find(params[:id])
    
    params[:abstract][:topic_ids] ||= []
    
    if @abstract.update_attributes_with_draft(params[:abstract])
      if params[:save_and_preview]
        redirect_to preview_abstract_path(@abstract)
      elsif params[:revert_to_published] && @abstract.has_published?
        @abstract.draft.destroy
        
        flash[:notice] = "This abstract's content has been reverted to the current published version."
        
        redirect_to edit_abstract_path(@abstract)
      elsif params[:publish] && @abstract.has_draft?
        @abstract.draft.publish
        
        flash[:notice] = "This abstract has been published successfully."
        
        redirect_to edit_abstract_path(@abstract)
      else
        flash[:notice] = 'This abstract has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_abstract_path(@abstract)
      end
    else
      @version = @abstract.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This abstract has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @abstract = Abstract.find(params[:id])
    
    @content_for_header_content = header_content_for_page('research')
    @content_for_body_class = body_class_for_page('research')
    
    @version = @abstract.draft
    
    @topics = ResearchTopic.all_published
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  # reorder the items
  def order
    if params[:abstracts]
      abstracts = params[:abstracts].to_a
      
      abstracts.each_with_index do |id, index|
        abstract = Abstract.find(id)
        
        abstract.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the abstracts has been updated."
    
    redirect_to abstracts_path
  end
  
  protected
    def load_lookups
      @topics = ResearchTopic.all_published
    end
end
