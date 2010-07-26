class Admin::PressReleasesController < ApplicationController
  layout 'admin'  
  
  cache_sweeper :press_release_sweeper, :only => [ :create, :update, :order ]
  
  before_filter :load_lookups, :only => [ :new, :create, :edit, :update ]
  
  def index
    @active_releases = PressRelease.active
    @inactive_releases = PressRelease.inactive
  end
  
  def new
    @press_release = PressRelease.new
    @upload = FileUpload.new
  end
  
  def create
    @press_release = PressRelease.new(params[:press_release])
    
    if @press_release.save
      flash[:notice] = "This release has been added successfully."
      
      unless params[:file_upload][:uploaded_data].blank?
        @upload = FileUpload.new(params[:file_upload])
        
        if @upload.save
          @press_release.update_attribute(:file_upload_id, @upload.id)
        end
      end
      
      redirect_to edit_press_release_path(@press_release)
    else
      @upload = FileUpload.new
      render :action => 'new'
    end
  end
  
  def edit
    @press_release = PressRelease.find(params[:id])
    @upload = FileUpload.new
  end
  
  def update
    @press_release = PressRelease.find(params[:id])
    
    if @press_release.update_attributes(params[:press_release])
      flash[:notice] = "This release has been saved successfully."
      
      unless params[:file_upload][:uploaded_data].blank?
        @upload = FileUpload.new(params[:file_upload])
        
        if @upload.save
          @press_release.update_attribute(:file_upload_id, @upload.id)
        end
      end
      
      redirect_to edit_press_release_path(@press_release)
    else
      @upload = FileUpload.new
      render :action => 'edit'
    end
  end
  
  protected
    def load_lookups
      @files = FileUpload.all
    end
end
