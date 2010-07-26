class HomePageImagesController < ApplicationController
  layout 'admin'  
  
  def index
    @images = HomePageImage.all
    @image = HomePageImage.new
    
    @home_page = HomePage.published
  end
  
  def create
    @image = HomePageImage.new(params[:home_page_image])
    
    if @image.save
      flash[:notice] = "Image has been uploaded successfully."
      
      if params[:from_slot]
        redirect_to change_home_slot_path(:slot => params[:from_slot])
      else
        redirect_to home_page_images_path
      end
    else
      @images = HomePageImage.all
      
      if params[:from_slot]
        @slot = params[:from_slot]
        
        @new_image = @image
        
        @image = HomePageImage.find_by_slot(params[:from_slot])    
        @image ||= HomePageImage.new
        
        render :action => 'change_slot'
      else
        @home_page = HomePage.published
        
        render :action => 'index'
      end
    end
  end
  
  def destroy
    @image = HomePageImage.find(params[:id])
    
    unless @image.in_use?
      @image.destroy
    end
    
    respond_to do |format|
      format.html { redirect_to home_page_images_path }
      format.js { head :ok }
    end
  end
  
  def change_slot
    @slot = params[:slot]
    
    @images = HomePageImage.all
    @new_image = HomePageImage.new
    
    @image = HomePageImage.find_by_slot(params[:slot])    
    @image ||= HomePageImage.new
  end
  
  def update_slot    
    expire_page(homepage_path)
    
    @slot = params[:slot]    
    @image = HomePageImage.find(params[:home_page_image_id])
    
    @old_images = HomePageImage.find_all_by_slot(@slot)
    
    @old_images.each do |i|
      i.update_attribute(:slot, "") unless @image.id == i.id
    end
    
    @image.update_attribute(:slot, @slot)
    
    flash[:notice] = "Home page images have been updated successfully."
    
    redirect_to home_page_images_path
  end
end