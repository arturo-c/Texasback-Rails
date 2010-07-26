class Admin::HomePageVersionsController < ApplicationController
  layout 'admin'  
  
  before_filter :load_draft_version
  
  cache_sweeper :home_sweeper, :only => [ :update_meta, :update_news, :update_wellness, :update_research, :update_review, :update_conditions, :update_events ]
  
  def index
    # blank
  end
  
  def edit_meta
    # meta fields
  end
  
  def update_meta
    @edit_path = edit_home_page_meta_path
    @edit_label = "meta data"
    @edit_action = "edit_meta"
    
    update_fields :page_title, :meta_description, :meta_keywords
  end
  
  def edit_news
    # news block
  end
  
  def update_news
    @edit_path = edit_home_page_news_path
    @edit_label = "news promo"
    @edit_action = "edit_news"
    
    update_fields :news_content, :news_link
  end
  
  def edit_wellness
    # wellness block
  end
  
  def update_wellness
    @edit_path = edit_home_page_wellness_path
    @edit_label = "wellness promo"
    @edit_action = "edit_wellness"
    
    update_fields :wellness_content, :wellness_link
  end
  
  def edit_research
    # research block
  end
  
  def update_research
    @edit_path = edit_home_page_research_path
    @edit_label = "research promo"
    @edit_action = "edit_research"
    
    update_fields :research_content, :research_link
  end
  
  def edit_review
    # testimonials block
  end
  
  def update_review
    @edit_path = edit_home_page_review_path
    @edit_label = "testimonials promo"
    @edit_action = "edit_review"
    
    update_fields :testimonials_content, :testimonials_link
  end
  
  def edit_events
    # events block
  end
  
  def update_events
    @edit_path = edit_home_page_events_path
    @edit_label = "events and outreach promo"
    @edit_action = "edit_events"
    
    update_fields :events_content, :events_link
  end
  
  def edit_conditions
    # conditions block
  end
  
  def update_conditions
    @edit_path = edit_home_page_conditions_path
    @edit_label = "conditions and treatments promo"
    @edit_action = "edit_conditions"
    
    update_fields :conditions_content
  end
  
  def preview
    flash.keep
    
    @home_page = Page.find_by_url('/', true)
      
    @home_page_content = HomePage.draft
    @live_home_page_content = HomePage.published
      
    @content_for_header_content = @home_page.part_content :header_content
    @content_for_body_class = @home_page.part_content :body_class      
      
    # load up all of the live content
    
    @meta_keywords        = @live_home_page_content.meta_keywords
    @meta_description     = @live_home_page_content.meta_description    
    @page_title           = @live_home_page_content.page_title    
    @news_link            = @live_home_page_content.news_link
    @wellness_link        = @live_home_page_content.wellness_link
    @research_link        = @live_home_page_content.research_link
    @testimonials_link    = @live_home_page_content.testimonials_link
    @news_link            = @live_home_page_content.news_link
    @wellness_link        = @live_home_page_content.wellness_link
    @research_link        = @live_home_page_content.research_link
    @testimonials_link    = @live_home_page_content.testimonials_link
    @conditions_content   = @live_home_page_content.conditions_content
    @events_content       = @live_home_page_content.events_content
    @events_link          = @live_home_page_content.events_link
    @news_content         = @live_home_page_content.news_content
    @wellness_content     = @live_home_page_content.wellness_content
    @research_content     = @live_home_page_content.research_content
    @testimonials_content = @live_home_page_content.testimonials_content
    
    # now only show the specific items we are previewing based on params[:from]
    
    case params[:from]
      when "edit_meta"
        @meta_keywords        = @home_page_content.meta_keywords
        @meta_description     = @home_page_content.meta_description
        @page_title           = @home_page_content.page_title
      when "edit_news"        
        @news_link            = @home_page_content.news_link
        @news_content         = @home_page_content.news_content
      when "edit_wellness"    
        @wellness_link        = @home_page_content.wellness_link
        @wellness_content     = @home_page_content.wellness_content
      when "edit_review"
        @testimonials_link    = @home_page_content.testimonials_link
        @testimonials_content = @home_page_content.testimonials_content
      when "edit_research"
        @research_link        = @home_page_content.research_link
        @research_content     = @home_page_content.research_content
      when "edit_conditions"
        @conditions_content   = @home_page_content.conditions_content
      when "edit_events"
        @events_content       = @home_page_content.events_content
        @events_link          = @home_page_content.events_link
    end
    
    @content_for_keywords = @meta_keywords
    @content_for_description = @meta_description
    @content_for_title_tag = @page_title
    
    @radiant_layout = "Default Layout"
    
    render :layout => 'radiant'
  end
  
  protected
    def update_fields(*attr_names)
      if @version.update_attributes(params[:home_page_version])
        if params[:save_and_preview]
          flash[:notice] = "The home page #{@edit_label} has been saved successfully.  <a href=\"#\" id=\"publish_link\">Publish</a>"
          
          redirect_to preview_home_page_path(:from => @edit_action)       
        elsif params[:revert_to_published]
          HomePage.revert_fields(*attr_names)

          flash[:notice] = "The home page #{@edit_label} has been reverted to the published version."

          redirect_to @edit_path
        elsif params[:publish]
          HomePage.publish_fields(*attr_names)

          flash[:notice] = "The home page #{@edit_label} has been published successfully."

          redirect_to @edit_path
        else
          flash[:notice] = "The home page #{@edit_label} has been saved successfully.  <a href=\"#\" id=\"publish_link\">Publish</a>"

          redirect_to @edit_path
        end
      else
        render :action => @edit_action
      end
    end
  
    def load_draft_version
      @version = HomePage.draft    
      @version = HomePage.create_draft unless @version
    end
end
