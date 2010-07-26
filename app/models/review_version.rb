class ReviewVersion < ActiveRecord::Base
  validates_presence_of :review_id, :content_status_id, :short_description, :full_description, :page_title
  
  validates_length_of :short_description, :maximum => 150
  
  belongs_to :content_status
  belongs_to :review
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
    if draft? && self.review
      existing_published_version = self.review.published
      
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
        other_versions = find_other_by_review_id_and_status(self.review_id, ContentStatus[:draft].id)
        
        errors.add :content_status_id, 'is already taken for this testimonial' if other_versions.length > 0
      end
      
      if self.published?
        other_versions = find_other_by_review_id_and_status(self.review_id, ContentStatus[:published].id)
        
        errors.add :content_status_id, 'is already taken for this testimonial' if other_versions.length > 0
      end
    end
    
    def find_other_by_review_id_and_status(review_id, content_status_id)
      if self.new_record?
        ReviewVersion.find_all_by_review_id_and_content_status_id(review_id, content_status_id)
      else
        ReviewVersion.find(:all, :conditions => [ "review_Id = ? AND content_status_id = ? AND id <> ?", review_id, content_status_id, self.id ])
      end
    end
end
