class Admin::EventsController < ApplicationController
  layout 'admin' 
  
  before_filter :load_lookups, :except => [ :preview ]
  
  cache_sweeper :event_sweeper, :only => [ :create, :update ]
  
  def index
    if params[:topic].to_i > 0
      @active = Event.find_all_with_topic(params[:topic]).paginate :page => params[:page], :per_page => 20
    else
      @active = Event.active.paginate :page => params[:page], :per_page => 20
    end   
        
    @inactive = Event.inactive
  end
  
  def show
    redirect_to edit_event_path(params[:id])
  end
  
  def new
    @event = Event.new
    @version = EventVersion.new
  end
  
  def create
    @event = Event.new(params[:event])
    
    if @event.save_with_draft
      flash[:notice] = 'This event has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_event_path(@event)
      else
        redirect_to edit_event_path(@event)
      end
    else
      @version = @event.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @event = Event.find(params[:id])
    
    if @event.has_draft?
      @version = @event.draft
    else
      @version = @event.create_draft
    end
  end
  
  def update
    @event = Event.find(params[:id])
    
    params[:event][:topic_ids] ||= []
    
    if @event.update_attributes_with_draft(params[:event])
      if params[:save_and_preview]
        redirect_to preview_event_path(@event)
      elsif params[:revert_to_published] && @event.has_published?
        @event.draft.destroy
        
        flash[:notice] = "This event's content has been reverted to the current published version."
        
        redirect_to edit_event_path(@event)
      elsif params[:publish] && @event.has_draft?
        @event.draft.publish
        
        flash[:notice] = "This event has been published successfully."
        
        redirect_to edit_event_path(@event)
      else
        flash[:notice] = 'This event has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_event_path(@event)
      end
    else
      @version = @event.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This event has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @event = Event.find(params[:id])
    
    @content_for_header_content = header_content_for_page('events')
    @content_for_body_class = body_class_for_page('events')
    
    @version = @event.draft
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @about_pages = AboutPage.all
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  protected  
    def load_lookups
      @topics = EventTopic.all_published
    end
end
