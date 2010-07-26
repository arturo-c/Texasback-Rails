class Admin::QuestionsController < ApplicationController
  layout 'admin'  
  
  before_filter :load_lookups, :only => [ :index, :new, :create, :edit, :update ]
  
  cache_sweeper :question_sweeper, :only => [ :create, :update, :order ]
  
  def index
    if params[:topic].to_i > 0
      @active = Question.find_all_with_topic(params[:topic])
    else
      @active = Question.active
    end
    
    @inactive = Question.inactive    
    
    @no_topics = Question.find_all_without_topics
  end
  
  def show
    redirect_to edit_question_path(params[:id])
  end
  
  def new
    @question = Question.new
    @version = QuestionVersion.new
  end
  
  def create
    @question = Question.new(params[:question])
    
    if @question.save_with_draft
      flash[:notice] = 'This question has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_question_path(@question)
      else
        redirect_to edit_question_path(@question)
      end
    else
      @version = @question.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @question = Question.find(params[:id])
    
    if @question.has_draft?
      @version = @question.draft
    else
      @version = @question.create_draft
    end
  end
  
  def update
    @question = Question.find(params[:id])
    
    params[:question][:topic_ids] ||= []
    
    if @question.update_attributes_with_draft(params[:question])
      if params[:save_and_preview]
        redirect_to preview_question_path(@question)
      elsif params[:revert_to_published] && @question.has_published?
        @question.draft.destroy
        
        flash[:notice] = "This question's content has been reverted to the current published version."
        
        redirect_to edit_question_path(@question)
      elsif params[:publish] && @question.has_draft?
        @question.draft.publish
        
        flash[:notice] = "This question has been published successfully."
        
        redirect_to edit_question_path(@question)
      else
        flash[:notice] = 'This question has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_question_path(@question)
      end
    else
      @version = @question.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This question has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @question = Question.find(params[:id])
    
    @content_for_header_content = header_content_for_page('ask_the_doctor')
    @content_for_body_class = body_class_for_page('ask_the_doctor')
    
    @version = @question.draft
    
    @topics = QuestionTopic.all_published
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  # reorder the items
  def order
    if params[:questions]
      questions = params[:questions].to_a
      
      questions.each_with_index do |id, index|
        question = Question.find(id)
        
        question.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the questions has been updated."
    
    redirect_to questions_path
  end
  
  # export results to excel
  def export    
    @from = DateTime.new(params[:question_export]["from(1i)"].to_i, params[:question_export]["from(2i)"].to_i, params[:question_export]["from(3i)"].to_i)
    @to = DateTime.new(params[:question_export]["to(1i)"].to_i, params[:question_export]["to(2i)"].to_i, params[:question_export]["to(3i)"].to_i, 23, 59, 59)
    
    @entries = AskDoctorEntry.find(:all, :conditions => [ "created_at >= ? AND created_at <= ?", @from, @to ])
    
    respond_to do |format|
      format.xls # export.xls.erb
    end
  rescue
    redirect_to admin_path
  end
  
  protected
    def load_lookups
      @topics = QuestionTopic.all_published
    end
end
