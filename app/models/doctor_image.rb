class DoctorImage < ActiveRecord::Base
  has_attachment :resize_to => [85, 85],
                 :storage => :file_system,
                 :path_prefix => 'public/_images/staff'
  
  attr_accessible :caption
  
  validate :check_content_type
  
  named_scope :all, :order => 'filename'
  
  has_many :doctor_versions
  
  def name
    self.filename
  end
  
  protected
    def check_content_type
      images = IMAGE_CONTENT_TYPES
      
      if self.content_type.nil?
        errors.add :uploaded_data, "^Please select a file."
      else
        unless images.include?(self.content_type.to_s.downcase)
          errors.add :uploaded_data, "^File must be an image."
        end
      end
    end
end