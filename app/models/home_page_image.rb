class HomePageImage < ActiveRecord::Base
  has_attachment :resize_to => [115, 107],
                 :storage => :file_system,
                 :path_prefix => 'public/_images/home'
  
  attr_accessible :caption
  
  validate :check_content_type
    
  def in_use?
    !slot.to_s.blank?
  end
    
  def self.path_for_slot(slot)
    image = HomePageImage.find_by_slot(slot.to_s)
    
    if image
      image.public_filename
    else
      "/_images/events_tab.jpg" # default image is just tbi HQ
    end
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