class Admin::HotelsController < ApplicationController
  layout 'admin'  
  
  cache_sweeper :hotel_sweeper, :only => [ :create, :update, :order ]
  
  def index
    case params[:preferred]
    when "yes"
      @hotels = Hotel.preferred
    when "no"
      @hotels = Hotel.not_preferred
    else
      @hotels = Hotel.active
    end
    
    @inactive = Hotel.inactive
  end
  
  def new
    @hotel = Hotel.new
  end
  
  def create
    @hotel = Hotel.new(params[:hotel])
    
    if @hotel.save
      flash[:notice] = "Hotel has been added successfully."
      
      redirect_to edit_hotel_path(@hotel)
    else
      render :action => 'new'
    end
  end
  
  def edit
    @hotel = Hotel.find(params[:id])
  end
  
  def update
    @hotel = Hotel.find(params[:id])
    
    if @hotel.update_attributes(params[:hotel])
      flash[:notice] = "Hotel has been saved successfully."
      
      redirect_to edit_hotel_path(@hotel)
    else
      render :action => 'edit'
    end
  end
  
  def order
    if params[:hotels]
      hotels = params[:hotels].to_a
      
      hotels.each_with_index do |loc_id, index|
        hotel = Hotel.find(loc_id)
        
        hotel.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the hotels has been updated."
    
    redirect_to hotels_path
  end
end
