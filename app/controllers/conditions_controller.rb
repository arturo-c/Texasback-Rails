class ConditionsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index, :show
  
  def index
    @conditions_page = Page.find_by_url('/conditions', true) #finds the live conditions page    
    
    @diagnostics_page = Page.find_by_url('/diagnostics', true)
    
    @diagnostics = Diagnostic.all_published
  end
  
  def show
    @condition = Condition.find_active_published_by_slug(params[:slug])
    @version = @condition.published
    
    @content_for_description = @version.meta_description
    @content_for_keywords = @version.meta_keywords
    @content_for_title_tag = @version.page_title
  rescue
    redirect_to conditions_list_path
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @content_for_header_content = header_content_for_page('conditions')
      @content_for_body_class = "specific_conditions"
      @content_for_title_tag = title_tag_for_page('conditions')
      
      @radiant_layout = "Default Layout"
    end
end