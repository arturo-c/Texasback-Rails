class ReviewsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index, :show, :condition
  
  def index
    @testimonials_page = Page.find_by_url('/testimonials', true) #finds the live testimonials page
    
    @content_for_description = @testimonials_page.description
    @content_for_keywords = @testimonials_page.keywords
    
    @conditions = Condition.all_published
    @reviews = Review.all_published
  end
  
  def show
    @review = Review.find_active_published_by_slug(params[:slug])
    
    @version = @review.published
    
    @content_for_description = @version.meta_description
    @content_for_keywords = @version.meta_keywords
    @content_for_title_tag = @version.page_title
  rescue
    redirect_to testimonials_list_path
  end
  
  def condition
    @condition = Condition.find_active_published_by_slug(params[:slug])
    
    @version = @condition.published
    
    @content_for_description = @version.meta_description
    @content_for_keywords = @version.meta_keywords
    @content_for_title_tag = @version.page_title
    
    @reviews = Review.find_all_published_with_condition(@condition.id)
  rescue
   redirect_to testimonials_list_path
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @content_for_header_content = header_content_for_page('testimonials')
      @content_for_body_class = body_class_for_page('testimonials')
      @content_for_title_tag = title_tag_for_page('testimonials')
      
      @radiant_layout = "Default Layout"
    end
end
