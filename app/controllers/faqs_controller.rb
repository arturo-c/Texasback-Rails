class FaqsController < ApplicationController
  layout 'radiant'
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index
  
  def index
    @faqs_page = Page.find_by_url('/about_us/faqs', true) #finds the live intro page
    
    @faqs = Faq.all_published
    
    @content_for_header_content = @faqs_page.part_content :header_content
    @content_for_body_class = @faqs_page.part_content :body_class
    @content_for_title_tag = @faqs_page.part_content :title_tag
    @content_for_keywords = @faqs_page.keywords
    @content_for_description = @faqs_page.description

    @radiant_layout = "Default Layout"
    
    @about_pages = AboutPage.all
    
    @about_page_name = "FAQs"
  end
end
