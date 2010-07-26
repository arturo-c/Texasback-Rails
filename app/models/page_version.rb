class PageVersion < ActiveRecord::Base
  belongs_to :page
  belongs_to :content_status
  
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'

  validates_presence_of :page_id, :content_status_id, :body_content, :page_title
  
  def published?
    self.content_status_id == ContentStatus[:published].id
  end  
  
  def archive?
    self.content_status_id == ContentStatus[:archive].id
  end
  
  def draft?
    self.content_status_id == ContentStatus[:draft].id
  end
  
  def status
    self.content_status
  end
  
  def modified?
    self.updated_at > self.created_at
  rescue
    false
  end
  
  def about_page?
    return (self.page.parent_id == 2)
  rescue
    false
  end
  
  # Promotes this version to published if its a draft, and remove any existing published versions
  def publish
    if draft? && self.page
      existing_published_version = PageVersion.find_by_page_id_and_content_status_id(self.page_id, ContentStatus[:published].id)
      
      if existing_published_version
        existing_published_version.update_attributes(:content_status_id => ContentStatus[:archive].id, :archive_date => Time.now)
      end
      
      self.content_status_id = ContentStatus[:published].id
      
      if self.save
        clear_cache
        
        self.page.update_content(:body => self.body_content, 
                                  :description => self.meta_description, 
                                  :keywords => self.meta_keywords,
                                  :page_title => self.page_title,
                                  :status_id => Status[:published].id,
                                  :secondary => self.secondary)
      else
        false
      end
    else
      false
    end
  end
  
  # loads a draft version for the given slug, returns nil if no page exists, or if there is no draft version available
  def self.find_draft_for_slug(slug)
    page = Page.find_by_slug(slug)
    
    PageVersion.find_draft_for_page(page)
  end
  
  def self.find_draft_for_page(page)
    if page
      PageVersion.find_by_page_id_and_content_status_id(page.id, ContentStatus[:draft].id)    
    else
      nil
    end
  end
  
  def self.create_for_slug(slug)
    page = Page.find_by_slug(slug)
    
    PageVersion.create_draft_for_page(page)
  end
  
  # creates a new draft version
  def self.create_draft_for_page(page)
    if page
      # make sure there is not already a draft for this slug      
      draft_version = PageVersion.find_by_page_id_and_content_status_id(page.id, ContentStatus[:draft].id)
      
      unless draft_version        
        draft_version = PageVersion.new(:page_id => page.id, 
                                        :body_content => page.part_content('body'),
                                        :page_title => page.part_content('title_tag'),
                                        :meta_keywords => page.keywords,
                                        :meta_description => page.description,
                                        :content_status_id => ContentStatus[:draft].id,
                                        :secondary => page.part_content('secondary'))
                                        
        if draft_version.page_title.blank? 
          draft_version.page_title = page.title
        end
        
        unless draft_version.save
          return nil
        end
      end
      
      draft_version
    else
      nil
    end
  end
  
  def clear_cache
		@cache ||= ResponseCache.instance
		
		@cache.clear
	end
  
  protected
    def validate
      # if this page is draft or published, there can be no other versions of that status      
      if self.draft?
        other_versions = find_other_by_page_id_and_status(self.page_id, ContentStatus[:draft].id)
        
        errors.add :content_status_id, 'is already taken for this page' if other_versions.length > 0
      end
      
      if self.published?
        other_versions = find_other_by_page_id_and_status(self.page_id, ContentStatus[:published].id)
        
        errors.add :content_status_id, 'is already taken for this page' if other_versions.length > 0
      end
      
      # content can't just be markup
      if errors.length == 0      
        test_content = self.body_content.gsub(/<[^>]*>/, '').gsub('&nbsp;', '').strip
      
        if test_content.blank?
          errors.add :body_content, "can't be blank."
        end
      end
    end
    
    def find_other_by_page_id_and_status(page_id, content_status_id)
      if self.new_record?
        PageVersion.find_all_by_page_id_and_content_status_id(page_id, content_status_id)
      else
        PageVersion.find(:all, :conditions => [ "page_id = ? AND content_status_id = ? AND id <> ?", page_id, content_status_id, self.id ])
      end
    end
end
