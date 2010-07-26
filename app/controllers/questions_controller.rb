class QuestionsController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  #session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :index, :show
  
  def index    
    @questions = Question.all_published
    
    @truncated_questions = true
  end
  
  def show
    @question = Question.find_active_published_by_slug(params[:slug])
    @version = @question.published
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
  end
  
  def ask_form
    @hide_form_link = true
    
    @entry = AskDoctorEntry.new
    
    @content_for_title_tag = "Ask The Doctor - Submit Your Question"
    @content_for_keywords = "back pain, lower back pain, back pain relief, low back pain, herniated disc, spinal stenosis, degenerative disc, radicular syndrome, osteoporosis, nerve compression, whiplash, sacroiliac joint pain, facet joint pain, texas back institute, tbi, submit a question"
    @content_for_description = "Submit your question to the Texas Back Institute doctors or contact us today for further information and to make your appointment."
  end
  
  def submit_ask_form
    @entry = AskDoctorEntry.new(params[:ask_doctor_entry])
    
    
      if @entry.save
        ContactFormMailer.deliver_doctor_question(@entry)

        flash[:ask_the_doctor] = @entry.id

        redirect_to ask_question_thanks_path
      else
        render :action => 'ask_form'
      end
    
  end
  
  def ask_form_thanks
    # blank
  end
  
  protected
    # allows rails to use this existing radiant layout by name
    def set_radiant_layout
      @ask_the_doctor_page = Page.find_by_url('/ask_the_doctor', true) #finds the live intro page
      
      @content_for_header_content = @ask_the_doctor_page.part_content :header_content
      @content_for_body_class = @ask_the_doctor_page.part_content :body_class
      @content_for_title_tag = @ask_the_doctor_page.part_content :title_tag
      
      @content_for_keywords = @ask_the_doctor_page.keywords
      @content_for_description = @ask_the_doctor_page.description

      @radiant_layout = "Default Layout"
      
      @topics = QuestionTopic.all_published
    end
end
