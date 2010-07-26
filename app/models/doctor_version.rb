class DoctorVersion < ActiveRecord::Base
  belongs_to :content_status
  belongs_to :doctor
  belongs_to :fellowship  
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  belongs_to :doctor_image
  
  validates_presence_of :doctor_id, :content_status_id, :page_title
  
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
    if draft? && self.doctor
      existing_published_version = self.doctor.published
      
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
  
  def has_bio?
    (self.doctor.has_publications? or (!self.doctor.photo_path.blank?) or (!self.awards.blank?) or (!self.certifications.blank?) or (!self.full_description.blank?))
  end
  
  # override the photo_path getter to now use the doctor_image file path
  def photo_path
    if doctor_image
      doctor_image.public_filename
    else
      self.doctor.photo_path
    end
  end
  
  protected
    def validate
      # if this page is draft or published, there can be no other versions of that status      
      if self.draft?
        other_versions = find_other_by_doctor_id_and_status(self.doctor_id, ContentStatus[:draft].id)
        
        errors.add :content_status_id, 'is already taken for this person' if other_versions.length > 0
      end
      
      if self.published?
        other_versions = find_other_by_doctor_id_and_status(self.doctor_id, ContentStatus[:published].id)
        
        errors.add :content_status_id, 'is already taken for this person' if other_versions.length > 0
      end
    end
    
    def find_other_by_doctor_id_and_status(doctor_id, content_status_id)
      if self.new_record?
        DoctorVersion.find_all_by_doctor_id_and_content_status_id(doctor_id, content_status_id)
      else
        DoctorVersion.find(:all, :conditions => [ "doctor_id = ? AND content_status_id = ? AND id <> ?", doctor_id, content_status_id, self.id ])
      end
    end
end
