class Admin::QuestionTopicsController < ApplicationController
  layout 'admin'
  
  cache_sweeper :question_sweeper, :only => [ :create, :update, :order ]
  
  def index
    @active = QuestionTopic.active
    @inactive = QuestionTopic.inactive
  end
  
  def show
    redirect_to edit_question_topic_path(params[:id])
  end
  
  def new
    @topic = QuestionTopic.new
    @version = QuestionTopicVersion.new
  end
  
  def create
    @topic = QuestionTopic.new(params[:question_topic])
    
    respond_to do |format|
      format.html do
        if @topic.save_with_draft
          flash[:notice] = 'This topic has been saved. <a href="#" id="publish_link">Publish</a>'

          if params[:save_and_preview]
            redirect_to preview_question_topic_path(@topic)
          else
            redirect_to edit_question_topic_path(@topic)
          end
        else
          @version = @topic.draft

          render :action => 'new'
        end
      end
      
      format.js do
        if @topic.save_with_draft
          @topic.update_attributes(:active_flag => true, :display_order => 99)
          @topic.draft.update_attributes(:meta_description => '', :meta_keywords => '')
          @topic.draft.publish
        end
      end
    end
  end
  
  def edit
    @topic = QuestionTopic.find(params[:id])
    
    if @topic.has_draft?
      @version = @topic.draft
    else
      @version = @topic.create_draft
    end
  end
  
  def update
    @topic = QuestionTopic.find(params[:id])
    
    if @topic.update_attributes_with_draft(params[:question_topic])
      if params[:save_and_preview]
        redirect_to preview_question_topic_path(@topic)
      elsif params[:revert_to_published] && @topic.has_published?
        @topic.draft.destroy
        
        flash[:notice] = "This topic's content has been reverted to the current published version."
        
        redirect_to edit_question_topic_path(@topic)
      elsif params[:publish] && @topic.has_draft?
        @topic.draft.publish
        
        flash[:notice] = "This topic has been published successfully."
        
        redirect_to edit_question_topic_path(@topic)
      else
        flash[:notice] = 'This topic has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_question_topic_path(@topic)
      end
    else
      @version = @topic.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This topic has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @topic = QuestionTopic.find(params[:id])
    
    @content_for_header_content = header_content_for_page('ask_the_doctor')
    @content_for_body_class = body_class_for_page('ask_the_doctor') 
    
    @version = @topic.draft
    
    @content_for_title_tag = @version.page_title
    @content_for_keywords = @version.meta_keywords
    @content_for_description = @version.meta_description
    
    @topics = QuestionTopic.all_published
    
    @truncated_questions = true
    
    @questions = Question.find_all_published_with_topic(@topic.id)
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  # reorder the items
  def order
    if params[:question_topics]
      topics = params[:question_topics].to_a
      
      topics.each_with_index do |topic_id, index|
        topic = QuestionTopic.find(topic_id)
        
        topic.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the topics has been updated."
    
    redirect_to question_topics_path
  end
end
