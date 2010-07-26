class HotelsController < ApplicationController
  layout 'radiant'
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
#  caches_page :index
  
  def index
    @page = Page.find_by_url('/appointments/out_of_town', true) #finds the live intro page
      
    @content_for_header_content = @page.part_content :header_content
    @content_for_body_class = @page.part_content :body_class
    @content_for_secondary = @page.part_content :secondary
    @content_for_title_tag = @page.part_content :title_tag
    @content_for_keywords = @page.keywords
    @content_for_description = @page.description
    
    @preferred_hotels = Hotel.preferred
    @other_hotels = Hotel.not_preferred

    @radiant_layout = "Default Layout"
  end
end
