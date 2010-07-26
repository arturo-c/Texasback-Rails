class Admin::FileUploadsController < ApplicationController
  def index
    @file = FileUpload.new
    
    @files = FileUpload.all
  end
  
  def create
    @file = FileUpload.new(params[:file_upload])
    @files = FileUpload.all
    
    @old_file = FileUpload.find_by_filename(@file.filename)
    
    if @old_file
      @old_file.destroy
    end
    
    if @file.save
      flash[:notice] = "Your file was uploaded."
      
      redirect_to file_uploads_path(:file => @file.id)
    else
      flash[:error] = "There was a problem uploading this file.  Please make sure the file does not already exist and try again."
      
      render :action => 'index'
    end
  end
end
