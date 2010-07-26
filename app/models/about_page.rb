class AboutPage < ActiveRecord::Base
  validates_presence_of :page_id
  validates_numericality_of :page_id
  
  belongs_to :page
  
  named_scope :all, :order => 'display_order'
  named_scope :all_custom, :conditions => { :custom_flag => true }, :order => 'display_order'
  
  def self.find_by_slug(slug)
    AboutPage.find_by_sql(["
      SELECT a.* FROM about_pages a, pages p
       WHERE p.id = a.page_id AND p.slug = ? AND p.status_id = ?
      ORDER BY a.display_order LIMIT 1", slug, Status[:published].id ])[0]
  end
  
  def parent
    @about_us_page ||= Page.find_by_slug('about_us')
  end
  
  def name
    self.page.title
  end
  
  def custom?
    self.custom_flag
  end
  
  def title
    title = self.page.part_content('title_tag')
    
    title = self.page.title if title.blank?
    
    title
  end
  
  def slug
    self.page.slug
  end
  
  def body
    self.page.part_content('body')
  end
  
  def body_class
    self.page.part_content('body_class')
  end
  
  def header_content
    self.page.part_content('header_content')
  end
  
  def secondary
    self.page.part_content('secondary')
  end
  
  def meta_description
    self.page.description
  end
  
  def meta_keywords
    self.page.keywords
  end
  
  def modified?
    self.updated_at > self.created_at
  end
  
  def published?
    self.page.published?
  end
  
  # this is used to create the page objects 
  def create_new_page(page_params, version_params)
    the_page = Page.new :slug => page_params[:slug], 
                        :title => page_params[:title], 
                        :breadcrumb => page_params[:slug],
                        :class_name => self.parent.class_name,
                        :parent_id => self.parent.id,
                        :layout_id => self.parent.layout_id,
                        :virtual => self.parent.virtual
    
    the_version = PageVersion.new :page_id => -1, 
                                :content_status_id => ContentStatus[:draft].id, 
                                :body_content => version_params[:body_content],
                                :page_title => version_params[:page_title],
                                :meta_keywords => version_params[:meta_keywords],
                                :meta_description => version_params[:meta_description]   
    
    # calling these separate so they both run and we can combine the errors
    page_valid = the_page.valid?
    version_valid = the_version.valid?
    
    if page_valid and version_valid
      if the_page.save
        # add some default content parts to that page
        the_page.update_part_content('body', version_params[:body_content])
        
        %w(header_content title_tag body_class secondary).each do |part|
          the_page.update_part_content(part, self.parent.part_content(part))
        end        
        
        the_version.page_id = the_page.id
        
        if the_version.save
          self.page_id = the_page.id
          self.display_order = 999
          self.custom_flag = true
          
          @page_object = the_page
          @version_object = the_version
          
          return self.save
        end
      end
    end
    
    merge_errors(the_page, the_version)
    
    @page_object = the_page
    @version_object = the_version
    
    return false
  end
  
  def update_page(page_params, version_params)
    if self.page.update_attributes(page_params)
      if self.version.update_attributes(version_params)        
        return true
      end
    end
    
    merge_errors(self.page, self.version)
    
    return false
  end
  
  def merge_errors(the_page, the_version)
    # Combine error messages from the page object (only including items that are on the form)
    if the_page.errors.length > 0
      errorable_attributes = %w(slug title url)
      
      the_page.errors.each do |field, msg|
        if field.to_s == "title"
          self.errors.add "page name", msg
        else
          self.errors.add field, msg if errorable_attributes.include?(field.downcase)
        end
      end
    end
    
    # Combine error messages from the version object (only including items that are on the form)
    if the_version.errors.length > 0
      errorable_attributes = %w(body_content meta_description meta_keywords page_title)
      
      the_version.errors.each do |field, msg|        
        self.errors.add field, msg if errorable_attributes.include?(field.downcase)
      end
    end
  end
  
  # returns the page for the current about_page instance
  def page
    @page_object ||= Page.find(self.page_id)
  end
  
  # returns the draft version for the current page
  def draft
    @version_object = PageVersion.find_draft_for_page(self.page)

    unless @page_version
      @version_object = PageVersion.create_draft_for_page(self.page)
    end
    
    @version_object
  end
  
  def version
    @version_object ||= self.draft
  end
end
