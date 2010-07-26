class Admin::EventImagesController < ApplicationController
  layout 'admin'
  
  before_filter :load_event
  
  # GET /admin/events/1/images
  def index 
    @image = EventImage.new
  end
  
  # GET /admin/events/1/images/new
  def new
     @image = @event.images.build
  end
  
  # POST /admin/events/1/images
  def create
    @image = @event.images.build(params[:event_image])
    
    if @image.save
      flash[:notice] = "Image has been uploaded successfully.  <br /><a href=\"#{edit_event_path(@event)}\">Return to editing #{@event.name} to save and publish this event</a>"
      
      redirect_to event_images_path(@event)
    else    
      render :action => 'index'
    end
  end
  
  # GET /admin/events/1/images/2
  def edit
    @image = @event.images.find(params[:id])
  end
  
  # PUT /admin/events/1/images/2
  def update
    @image = @event.images.find(params[:id])
    
    if @image.update_attributes(params[:event_image])
      flash[:notice] = "Image has been updated successfully. <br /><a href=\"#{edit_event_path(@event)}\">Return to editing #{@event.name} to save and publish this event</a>"
      
      redirect_to event_images_path(@event)
    else
      render :action => 'edit'
    end
  end
  
  # DELETE /admin/events/1/images/2
  def destroy
    @image = @event.images.find(params[:id])
    
    @image.destroy
    
    respond_to do |format|
      format.html { redirect_to event_images_path(@event) }
      format.js { head :ok }
    end
  end
  
  protected
    def load_event
      @event = Event.find(params[:event_id])
    end
end