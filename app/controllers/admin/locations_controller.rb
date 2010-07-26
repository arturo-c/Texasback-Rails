class Admin::LocationsController < ApplicationController
  layout 'admin'  
  
  cache_sweeper :location_sweeper, :only => [ :create, :update, :order ]
  
  def index
    if params[:state]
      @locations = Location.by_state(params[:state])
    else
      @locations = Location.all
    end    
  end
  
  def new
    @location = Location.new
  end
  
  def create
    @location = Location.new(params[:location])
    
    if @location.save
      flash[:notice] = "This location has been added successfully."
      
      redirect_to edit_location_path(@location)
    else
      render :action => 'new'
    end
  end
  
  def edit
    @location = Location.find(params[:id])
  end
  
  def update
    @location = Location.find(params[:id])
    
    if @location.update_attributes(params[:location])
      flash[:notice] = "This location has been saved successfully."
      
      redirect_to edit_location_path(@location)
    else
      render :action => 'edit'
    end
  end
  
  def order
    if params[:locations]
      locations = params[:locations].to_a
      
      locations.each_with_index do |loc_id, index|
        location = Location.find(loc_id)
        
        location.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the locations has been updated."
    
    if params[:state]
      redirect_to locations_path(:state => params[:state])
    else
      redirect_to locations_path
    end    
  end
end
