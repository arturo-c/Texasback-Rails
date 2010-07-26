class AbstractVersion < ActiveRecord::Base
  validates_presence_of :abstract_id, :content_status_id, :page_title
  
  belongs_to :abstract
  belongs_to :content_status
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'  
  
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
  end
  
  def publish
    if draft? && self.abstract
      existing_published_version = self.abstract.published
      
      if existing_published_version
        existing_published_version.update_attribute(:content_status_id, ContentStatus[:archive].id)
        existing_published_version.update_attribute(:archive_date, Time.now)
      end
      
      self.content_status_id = ContentStatus[:published].id
      
      self.save
    else
      false
    end
  end
  
  protected
    def validate
      # if this page is draft or published, there can be no other versions of that status      
      if self.draft?
        other_versions = find_other_by_abstract_id_and_status(self.abstract_id, ContentStatus[:draft].id)
        
        errors.add :content_status_id, 'is already taken for this abstract' if other_versions.length > 0
      end
      
      if self.published?
        other_versions = find_other_by_abstract_id_and_status(self.abstract_id, ContentStatus[:published].id)
        
        errors.add :content_status_id, 'is already taken for this abstract' if other_versions.length > 0
      end
    end
    
    def find_other_by_abstract_id_and_status(abstract_id, content_status_id)
      if self.new_record?
        AbstractVersion.find_all_by_abstract_id_and_content_status_id(abstract_id, content_status_id)
      else
        AbstractVersion.find(:all, :conditions => [ "abstract_id = ? AND content_status_id = ? AND id <> ?", abstract_id, content_status_id, self.id ])
      end
    end
end
