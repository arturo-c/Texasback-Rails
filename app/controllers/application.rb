require_dependency 'radiant'

class ApplicationController < ActionController::Base
  include LoginSystem
  
  filter_parameter_logging :password, :password_confirmation
  
  protect_from_forgery
  
  before_filter :set_current_user
  before_filter :set_javascripts_and_stylesheets
  
  attr_accessor :config
  
  def initialize
    super
    @config = Radiant::Config
  end
  
  # helpers to include additional assets from actions or views
  helper_method :include_stylesheet, :include_javascript
  
  def include_stylesheet(sheet)
    @stylesheets << sheet
  end
  
  def include_javascript(script)
    @javascripts << script
  end
  
  def rescue_action_in_public(exception)
    case exception
      when ActiveRecord::RecordNotFound, ActionController::UnknownController, ActionController::UnknownAction, ActionController::RoutingError
        render :template => "site/not_found", :status => 404
      else
        super
    end
  end
  
  # returns the header_content page part for the given page slug
  def header_content_for_page(slug)
    content = ""
    
    @slug_page ||= Page.find_by_slug(slug)
    
    if @slug_page
      content = @slug_page.part_content("header_content")
    end
    
    content
  end
  
  # returns the body_class page part for the given page slug
  def body_class_for_page(slug)
    content = ""
    
    @slug_page ||= Page.find_by_slug(slug)
    
    if @slug_page
      content = @slug_page.part_content("body_class")
    end
    
    content
  end
  
  # returns the title_tag page part for the given page slug
  def title_tag_for_page(slug)
    content = ""
    
    @slug_page ||= Page.find_by_slug(slug)
    
    if @slug_page
      content = @slug_page.part_content("title_tag")
    end
    
    content
  end
  
  def captcha_verified?
    if Rails.configuration.environment == "test" 
      true
    else
      verify_recaptcha
    end
  end
  
  private
  
    def set_current_user
      UserActionObserver.current_user = current_user
    end
  
    def set_javascripts_and_stylesheets
      @stylesheets ||= []
      @stylesheets.concat %w(admin/main)
      @javascripts ||= []
      @javascripts.concat %w(prototype string effects admin/tabcontrol admin/ruledtable admin/admin)
    end
end
