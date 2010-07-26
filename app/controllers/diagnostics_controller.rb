class DiagnosticsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :show
  
  def show
    @diagnostic = Diagnostic.find_active_published_by_slug(params[:slug])
    
    @version = @diagnostic.published
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @diagnostics = Diagnostic.all_published
  rescue
    redirect_to conditions_list_path
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @content_for_header_content = header_content_for_page('diagnostics')
      @content_for_body_class = body_class_for_page('diagnostics')
      @content_for_title_tag = title_tag_for_page('diagnostics')
      
      @radiant_layout = "Default Layout"
    end
end
