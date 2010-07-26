class Admin::FaqsController < ApplicationController
  layout 'admin'
  
  cache_sweeper :faq_sweeper, :only => [ :create, :update, :order ]
  
  def index    
    @active = Faq.active    
    @inactive = Faq.inactive
  end
  
  def show
    redirect_to edit_faq_path(params[:id])
  end
  
  def new
    @faq = Faq.new
    @version = FaqVersion.new
  end
  
  def create
    @faq = Faq.new(params[:faq])
    
    if @faq.save_with_draft
      flash[:notice] = 'This FAQ has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_faq_path(@faq)
      else
        redirect_to edit_faq_path(@faq)
      end
    else
      @version = @faq.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @faq = Faq.find(params[:id])
    
    if @faq.has_draft?
      @version = @faq.draft
    else
      @version = @faq.create_draft
    end
  end
  
  def update
    @faq = Faq.find(params[:id])
    
    if @faq.update_attributes_with_draft(params[:faq])
      if params[:save_and_preview]
        redirect_to preview_faq_path(@faq)
      elsif params[:revert_to_published] && @faq.has_published?
        @faq.draft.destroy
        
        flash[:notice] = "This FAQ's content has been reverted to the current published version."
        
        redirect_to edit_faq_path(@faq)
      elsif params[:publish] && @faq.has_draft?
        @faq.draft.publish
        
        flash[:notice] = "This FAQ has been published successfully."
        
        redirect_to edit_faq_path(@faq)
      else
        flash[:notice] = 'This FAQ has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_faq_path(@faq)
      end
    else
      @version = @faq.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This FAQ has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @faq = Faq.find(params[:id])
    @version = @faq.draft
    
    @faqs_page = Page.find_by_url('/about_us/faqs', true) #finds the live intro page 
    
    @content_for_header_content = @faqs_page.part_content :header_content
    @content_for_body_class = @faqs_page.part_content :body_class
    @content_for_title_tag = @faqs_page.part_content :title_tag
    @content_for_keywords = @faqs_page.keywords
    @content_for_description = @faqs_page.description
    
    @about_pages = AboutPage.all
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  # reorder the items
  def order
    if params[:faqs]
      faqs = params[:faqs].to_a
      
      faqs.each_with_index do |id, index|
        faq = Faq.find(id)
        
        faq.update_attributes(:display_order => index)
      end
    end
    
    flash[:notice] = "The display order for the FAQs has been updated."
    
    redirect_to faqs_path
  end
end
