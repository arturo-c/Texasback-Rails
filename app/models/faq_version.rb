class FaqVersion < ActiveRecord::Base
  belongs_to :faq
  belongs_to :content_status
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  
  validates_presence_of :faq_id, :content_status_id, :question, :answer
  
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
    if draft? && self.faq
      existing_published_version = self.faq.published
      
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
        other_versions = find_other_by_faq_id_and_status(self.faq_id, ContentStatus[:draft].id)
        
        errors.add :content_status_id, 'is already taken for this FAQ' if other_versions.length > 0
      end
      
      if self.published?
        other_versions = find_other_by_faq_id_and_status(self.faq_id, ContentStatus[:published].id)
        
        errors.add :content_status_id, 'is already taken for this FAQ' if other_versions.length > 0
      end
    end
    
    def find_other_by_faq_id_and_status(faq_id, content_status_id)
      if self.new_record?
        FaqVersion.find_all_by_faq_id_and_content_status_id(faq_id, content_status_id)
      else
        FaqVersion.find(:all, :conditions => [ "faq_id = ? AND content_status_id = ? AND id <> ?", faq_id, content_status_id, self.id ])
      end
    end
end
