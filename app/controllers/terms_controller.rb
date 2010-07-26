class TermsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index, :show
  
  def index
    @group = TermGroup.find(:first)    
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @glossary_page = Page.find_by_url('/about_us/glossary', true) #finds the live intro page
      @content_for_header_content = @glossary_page.part_content :header_content
      @content_for_body_class = @glossary_page.part_content :body_class
      @content_for_title_tag = @glossary_page.part_content :title_tag
      @content_for_keywords = @glossary_page.keywords
      @content_for_description = @glossary_page.description    

      @groups = TermGroup.all
      
      @radiant_layout = "Default Layout"      
      
      @about_pages = AboutPage.all
      
      @about_page_name = "Glossary"
    end
end
