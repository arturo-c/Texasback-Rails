class LocationsController < ApplicationController
  layout 'radiant'
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index
  
  def index
    @locations_page = Page.find_by_url('/locations', true) #finds the live intro page
    
    @tx_locations = Location.all.by_state('TX')
    @az_locations = Location.all.by_state('AZ')
    
    @teams = Team.with_locations
    
    @content_for_header_content = @locations_page.part_content :header_content
    @content_for_body_class = @locations_page.part_content :body_class
    #@content_for_secondary = @locations_page.part_content :secondary
    @content_for_title_tag = @locations_page.part_content :title_tag
    @content_for_keywords = @locations_page.keywords
    @content_for_description = @locations_page.description

    @radiant_layout = "Default Layout"
  end
  
  def doctors
    params[:location_id] ||= "all"
    
    if params[:location_id] == "all"
      @location = nil
    else
      @location = Location.find(params[:location_id])
    end
    
    @team = Team.find(params[:team_id])
    
    if @location
      @doctors = Doctor.published_with_location_and_team(@location.id, @team.id)
    else
      @doctors = Doctor.published_with_team(@team.id)
    end    
    
    respond_to do |format|
      format.js #doctors.js.rjs
      format.html { redirect_to view_locations_path }
    end
  end
end
