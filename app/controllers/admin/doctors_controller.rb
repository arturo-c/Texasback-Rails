class Admin::DoctorsController < ApplicationController
  layout 'admin'  
  
  before_filter :load_form_lookups, :only => [ :new, :create, :edit, :update ]
  
  cache_sweeper :doctor_sweeper, :only => [ :create, :update, :order ]
  
  def index
    if params[:location].to_i > 0 || params[:team].to_i > 0
      @active = Doctor.find_all_with_team_and_location(params[:team], params[:location])
    else
      @active = Doctor.active
    end    
    
    @inactive = Doctor.inactive
    
    @teams = Team.all
    @locations = Location.all
  end
  
  def new
    @doctor = Doctor.new
    @version = DoctorVersion.new    
  end
  
  def create
    @doctor = Doctor.new(params[:doctor])
    
    if @doctor.save_with_draft
      flash[:notice] = 'This person has been saved. <a href="#" id="publish_link">Publish</a>'
      
      unless params[:file_upload][:uploaded_data].blank?
        @upload = FileUpload.new(params[:file_upload])
        
        if @upload.save
          @doctor.update_attribute(:publications_file_id, @upload.id)
        end
      end      
      
      if params[:save_and_preview]
        redirect_to preview_doctor_path(@doctor)
      else
        redirect_to edit_doctor_path(@doctor)
      end
    else
      @version = @doctor.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @doctor = Doctor.find(params[:id])
    
    if @doctor.has_draft?
      @version = @doctor.draft
    else
      @version = @doctor.create_draft
    end
  end
  
  def update
    @doctor = Doctor.find(params[:id])
    
    params[:doctor][:credential_ids] ||= []
    params[:doctor][:location_ids] ||= []
    params[:doctor][:team_ids] ||= []
    
    if @doctor.update_attributes_with_draft(params[:doctor])
      unless params[:file_upload][:uploaded_data].blank?
        @upload = FileUpload.new(params[:file_upload])
        
        if @upload.save
          @doctor.update_attribute(:publications_file_id, @upload.id)
        end
      end
      
      # doctor bio image
      unless params[:doctor_image][:uploaded_data].blank?
        @doctor_image = DoctorImage.new(params[:doctor_image])
        
        if @doctor_image.save
          @doctor.draft.update_attributes(:doctor_image_id => @doctor_image.id)
        end
      end
      
      if params[:save_and_preview]
        redirect_to preview_doctor_path(@doctor)
      elsif params[:revert_to_published] && @doctor.has_published?
        @doctor.draft.destroy
        
        flash[:notice] = "This person's content has been reverted to the current published version."
        
        redirect_to edit_testimonial_path(@doctor)
      elsif params[:publish] && @doctor.has_draft?
        @doctor.draft.publish
        
        flash[:notice] = "This person has been published successfully."
        
        redirect_to edit_doctor_path(@doctor)
      else
        flash[:notice] = 'This person has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_doctor_path(@doctor)
      end
    else
      @version = @doctor.draft
      
      render :action => 'edit'
    end
  end
  
  # reorder the items
  def order
    if params[:doctors]
      doctors = params[:doctors].to_a
      
      doctors.each_with_index do |doctor_id, index|
        doctor = Doctor.find(doctor_id)
        
        doctor.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the doctors has been updated."
    
    redirect_to doctors_path
  end
  
  def preview
    flash[:notice] = 'This person has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @doctor = Doctor.find(params[:id])
    
    @content_for_header_content = header_content_for_page('our_doctors_and_staff')
    @content_for_body_class = body_class_for_page('ask_the_doctor')
    
    @version = @doctor.draft
    
    @hide_anchors = true
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @about_pages = AboutPage.all
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  def publications
    @label = TbiConfig[:publications_label]
    @intro = TbiConfig[:publications_intro]
  end
  
  def config
    @label = params[:publications_label]
    @intro = params[:publications_intro]
    
    if @label.blank?
      @error = true
      
      render :action => 'publications'
    else
      TbiConfig.update_config(:publications_label, @label)
      TbiConfig.update_config(:publications_intro, @intro)
      
      flash[:notice] = "Publication labels have been updated successfully."
      
      redirect_to publications_doctors_path
    end
  end
  
  def load_form_lookups
    @specialties = Specialty.all
    @locations = Location.all
    @credentials = Credential.all
    @fellowships = Fellowship.all
    @teams = Team.all
    @upload = FileUpload.new
    @files = FileUpload.all
    @doctor_image = DoctorImage.new
    @doc_images = DoctorImage.all
  end
end
