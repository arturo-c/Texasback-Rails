class Admin::TermsController < ApplicationController
  layout 'admin' 
  
  before_filter :load_lookups, :except => [ :preview ]
  
  cache_sweeper :term_sweeper, :only => [ :create, :update ]
  
  def index
    if params[:group].to_i > 0
      @active = Term.active.by_group(params[:group]).paginate :page => params[:page], :per_page => 20
    else
      @active = Term.active.paginate :page => params[:page], :per_page => 20
    end   
        
    @inactive = Term.inactive
  end
  
  def show
    redirect_to edit_term_path(params[:id])
  end
  
  def new
    @term = Term.new
    @version = TermVersion.new
  end
  
  def create
    @term = Term.new(params[:term])
    
    if @term.save_with_draft
      flash[:notice] = 'This term has been saved. <a href="#" id="publish_link">Publish</a>'
      
      if params[:save_and_preview]
        redirect_to preview_term_path(@term)
      else
        redirect_to edit_term_path(@term)
      end
    else
      @version = @term.draft
      
      render :action => 'new'
    end
  end
  
  def edit
    @term = Term.find(params[:id])
    
    if @term.has_draft?
      @version = @term.draft
    else
      @version = @term.create_draft
    end
  end
  
  def update
    @term = Term.find(params[:id])
    
    if @term.update_attributes_with_draft(params[:term])
      if params[:save_and_preview]
        redirect_to preview_term_path(@term)
      elsif params[:revert_to_published] && @term.has_published?
        @term.draft.destroy
        
        flash[:notice] = "This term's content has been reverted to the current published version."
        
        redirect_to edit_term_path(@term)
      elsif params[:publish] && @term.has_draft?
        @term.draft.publish
        
        flash[:notice] = "This term has been published successfully."
        
        redirect_to edit_term_path(@term)
      else
        flash[:notice] = 'This term has been saved. <a href="#" id="publish_link">Publish</a>'
        
        redirect_to edit_term_path(@term)
      end
    else
      @version = @term.draft
      
      render :action => 'edit'
    end
  end
  
  def preview
    flash[:notice] = 'This term has been saved. <a href="#" id="publish_link">Publish</a>'
    
    @term = Term.find(params[:id])
    
    @glossary_page = Page.find_by_url('/about_us/glossary', true) #finds the live intro page
    @content_for_header_content = @glossary_page.part_content :header_content
    @content_for_body_class = @glossary_page.part_content :body_class
    @content_for_title_tag = @glossary_page.part_content :title_tag
    @content_for_keywords = @glossary_page.keywords
    @content_for_description = @glossary_page.description    

    @groups = TermGroup.all
    
    @version = @term.draft
    
    @about_pages = AboutPage.all
    
    @radiant_layout = "Default Layout"        
    
    render :layout => 'radiant'
  end
  
  protected  
    def load_lookups
      @groups = TermGroup.all
    end
end
