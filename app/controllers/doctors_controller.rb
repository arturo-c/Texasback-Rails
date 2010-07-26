class DoctorsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :show
  
  def index
    @doctors_by_name = Doctor.published_by_name
    @doctors_by_tenure = Doctor.all_published
    @teams = Team.with_published_doctors
    @locations = Location.all
    
    @texas = Location.by_state('TX')
    @zona = Location.by_state('AZ')
  end
  
  def show
    @doctor = Doctor.find_active_published_by_slug(params[:slug])
    @version = @doctor.published
    
    @hide_anchors = true
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @doctors_page = Page.find_by_url('/about_us/our_doctors_and_staff', true) #finds the live intro page    
      @content_for_keywords = @doctors_page.keywords
      @content_for_description = @doctors_page.description
      
      @content_for_header_content = header_content_for_page('our_doctors_and_staff')
      @content_for_body_class = body_class_for_page('our_doctors_and_staff')
      @content_for_title_tag = title_tag_for_page('our_doctors_and_staff')

      @radiant_layout = "Default Layout"
      
      @about_pages = AboutPage.all
      
      @about_page_name = "Our Doctors and Staff"
    end
end
