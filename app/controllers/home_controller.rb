class HomeController < ApplicationController
  layout 'radiant'

  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index, :site_map
  
  def index
    @home_page = Page.find_by_url('/', true)

    @home_page_content = HomePage.published
    
    @content_for_keywords = @home_page_content.meta_keywords
    @content_for_description = @home_page_content.meta_description
    @content_for_header_content = @home_page.part_content :header_content
    @content_for_body_class = @home_page.part_content :body_class
    @content_for_title_tag = @home_page_content.page_title
    
    @radiant_layout = "Default Layout"
  end
  
  def site_map
    @site_map_page = Page.find_by_url('/site_map', true)

    @content_for_keywords = @site_map_page.keywords
    @content_for_description = @site_map_page.description
    @content_for_header_content = @site_map_page.part_content :header_content
    @content_for_body_class = @site_map_page.part_content :body_class
    @content_for_title_tag = @site_map_page.part_content :title_tag
    
    @conditions = Condition.all_published
    @treatment_types = TreatmentType.top_level
    @about_pages = AboutPage.all
    @diagnostics = Diagnostic.all_published
    
    @radiant_layout = "Default Layout"
  end
  
  def info
    # environment info
  end
end
