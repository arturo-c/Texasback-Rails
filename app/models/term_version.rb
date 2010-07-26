class TermVersion < ActiveRecord::Base
  belongs_to :term
  belongs_to :content_status
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  
  
  validates_presence_of :content_status_id, :term_id, :definition
  
  def status
    self.content_status
  end
  
  def published?
    self.content_status_id == ContentStatus[:published].id
  end  
  
  def archive?
    self.content_status_id == ContentStatus[:archive].id
  end
  
  def draft?
    self.content_status_id == ContentStatus[:draft].id
  end
  
  def modified?
    self.updated_at > self.created_at
  end
  
  def publish
     if draft? && self.term
       existing_published_version = self.term.published

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
         other_versions = find_other_by_term_id_and_status(self.term_id, ContentStatus[:draft].id)

         errors.add :content_status_id, 'is already taken for this term' if other_versions.length > 0
       end

       if self.published?
         other_versions = find_other_by_term_id_and_status(self.term_id, ContentStatus[:published].id)

         errors.add :content_status_id, 'is already taken for this term' if other_versions.length > 0
       end
     end

     def find_other_by_term_id_and_status(term_id, content_status_id)
       if self.new_record?
         TermVersion.find_all_by_term_id_and_content_status_id(term_id, content_status_id)
       else
         TermVersion.find(:all, :conditions => [ "term_id = ? AND content_status_id = ? AND id <> ?", term_id, content_status_id, self.id ])
       end
     end
end
