class Admin::ConditionImagesController < ApplicationController
  layout 'admin'
  
  before_filter :load_condition
  
  # GET /admin/conditions/1/images
  def index 
    @image = ConditionImage.new
  end
  
  # GET /admin/conditions/1/images/new
  def new
     @image = @condition.images.build
  end
  
  # POST /admin/conditions/1/images
  def create
    @image = @condition.images.build(params[:condition_image])
    
    if @image.save
      flash[:notice] = "Image has been uploaded successfully.  <br /><a href=\"#{edit_condition_path(@condition)}\">Return to editing #{@condition.name} to save and publish this condition</a>"
      
      redirect_to condition_images_path(@condition)
    else    
      render :action => 'index'
    end
  end
  
  # GET /admin/conditions/1/images/2
  def edit
    @image = @condition.images.find(params[:id])
  end
  
  # PUT /admin/conditions/1/images/2
  def update
    @image = @condition.images.find(params[:id])
    
    if @image.update_attributes(params[:condition_image])
      flash[:notice] = "Image has been updated successfully. <br /><a href=\"#{edit_condition_path(@condition)}\">Return to editing #{@condition.name} to save and publish this condition</a>"
      
      redirect_to condition_images_path(@condition)
    else
      render :action => 'edit'
    end
  end
  
  # DELETE /admin/conditions/1/images/2
  def destroy
    @image = @condition.images.find(params[:id])
    
    @image.destroy
    
    respond_to do |format|
      format.html { redirect_to condition_images_path(@condition) }
      format.js { head :ok }
    end
  end
  
  protected
    def load_condition
      @condition = Condition.find(params[:condition_id])
    end
end