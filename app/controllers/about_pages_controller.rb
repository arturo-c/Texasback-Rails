class AboutPagesController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index, :show
  
  def index
    @page = Page.find_by_url('/about_us', true) #finds the live about us index page
    
    @content_for_description = @page.description
    @content_for_keywords = @page.keywords
    @content_for_header_content = @page.part_content :header_content
    @content_for_body_class = @page.part_content :body_class
    @content_for_title_tag = @page.part_content :title_tag
  end
  
  def show
    @about_page = AboutPage.find_by_slug(params[:slug])
    
    @content_for_description = @about_page.meta_description
    @content_for_keywords = @about_page.meta_keywords
    @content_for_header_content = @about_page.header_content
    @content_for_body_class = @about_page.body_class
    @content_for_title_tag = @about_page.title
  rescue
    redirect_to about_us_path
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @radiant_layout = "Default Layout"
      
      @about_pages = AboutPage.all
    end
end
