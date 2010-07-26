class NewsAndMediaController < ApplicationController
  layout 'radiant'
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index
  
  def index
    @page = Page.find_by_url('/about_us/news_and_media', true)
    
    @releases = PressRelease.active
    @about_pages = AboutPage.all
    @media_entries = MediaEntry.active
    
    @about_page_name = "News and Media"
    
    @content_for_header_content = @page.part_content :header_content
    @content_for_body_class = @page.part_content :body_class
    @content_for_secondary = @page.part_content :secondary
    @content_for_title_tag = @page.part_content :title_tag
    @content_for_keywords = @page.keywords
    @content_for_description = @page.description

    @radiant_layout = "Default Layout"
  end
end
