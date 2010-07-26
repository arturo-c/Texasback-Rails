class ResearchTopicsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index, :show
  
  def index
    @research_page = Page.find_by_url('/research', true) #finds the live research page@
    
    @content_for_description = @research_page.description
    @content_for_keywords = @research_page.keywords
  end
  
  def show
    @topic = ResearchTopic.find_active_published_by_slug(params[:slug])
    @version = @topic.published    
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
  rescue
    redirect_to research_topics_list_path
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @content_for_header_content = header_content_for_page('research')
      @content_for_body_class = body_class_for_page('research')
      @content_for_title_tag = title_tag_for_page('research')

      @radiant_layout = "Default Layout"
      
      @topics = ResearchTopic.all_published
    end
end
