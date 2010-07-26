class QuestionTopicsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :show
  
  def show
    @topic = QuestionTopic.find_active_published_by_slug(params[:slug])
    
    @content_for_title_tag = @topic.published.page_title
    @content_for_keywords = @topic.published.meta_keywords
    @content_for_description = @topic.published.meta_description
    
    @truncated_questions = true
    
    @questions = Question.find_all_published_with_topic(@topic.id)
  rescue
    redirect_to questions_list_path 
  end
    
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @content_for_header_content = header_content_for_page('ask_the_doctor')
      @content_for_body_class = body_class_for_page('ask_the_doctor')
      @content_for_title_tag = title_tag_for_page('ask_the_doctor')

      @radiant_layout = "Default Layout"
      
      @topics = QuestionTopic.all_published
    end
end
