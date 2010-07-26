class EventsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index, :show, :month
  
  def index
    @events_page = Page.find_by_url('/about_us/events', true) #finds the live intro page

    @content_for_keywords = @events_page.keywords
    @content_for_description = @events_page.description

    @months = next_months(6)
    
    @events = Event.all_published.upcoming 
  end
  
  def month
    redirect_to events_list_path unless valid_date_params?
    
    @events_page = Page.find_by_url('/about_us/events', true) #finds the live intro page

    @content_for_keywords = @events_page.keywords
    @content_for_description = @events_page.description
    
    @months = next_months(6)
    
    @selected_date = Time.parse("#{params[:year]}-#{params[:month]}-01")
    
    @events = Event.all_published.by_month(@selected_date)
  end
  
  def topic
    @events_page = Page.find_by_url('/about_us/events', true) #finds the live intro page

    @months = next_months(6)
    
    @topic = EventTopic.find_active_published_by_slug(params[:slug])
    
    @content_for_keywords = @topic.published.meta_keywords
    @content_for_description = @topic.published.meta_description
    @content_for_title_tag = @topic.published.page_title
    
    @events = Event.published_upcoming_with_topic(@topic.id)
  end
  
  def show
    @event = Event.find(params[:id])
    
    redirect_to events_list_path unless @event.has_published?
    
    @version = @event.published
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description    
  rescue
    redirect_to events_list_path
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @content_for_header_content = header_content_for_page('events')
      @content_for_body_class = body_class_for_page('events')
      @content_for_title_tag = title_tag_for_page('events')

      @radiant_layout = "Default Layout"
      
      @about_pages = AboutPage.all
      
      @about_page_name = "Events"
    end
    
    def valid_date_params?
      month = params[:month].to_i
      year = params[:year].to_i
      
      return (month > 0 && month < 13) && (year > 1900 && year < 2100)
    end
    
    def next_months(number)    
      months = []
      
      this_month = Time.parse "#{Date.today.year}-#{Date.today.month}-01"
      
      number.times { |i| months << i.months.since(this_month) }
      
      months
    end
end
