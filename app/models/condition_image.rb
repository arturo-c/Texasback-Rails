class ConditionImage < ActiveRecord::Base
  has_attachment :content_type => :images, 
                 :thumbnails => { :thumb => [65, 80] },
                 :storage => :file_system,
                 :path_prefix => 'public/_images/conditions'
  
  belongs_to :condition
  has_many :condition_version_images, :dependent => :destroy
  
  attr_accessible :caption, :small_caption
  
  validate :check_captions
  validate :check_content_type
  
  after_save :update_condition_timestamp
    
  protected
    def check_captions
      if thumbnail.blank?
        if caption.blank?
          errors.add :caption, "^Full caption can't be blank"
        end
        
        if small_caption.blank?
          errors.add :small_caption, "can't be blank"
        end
      end
    end
    
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
    
    def update_condition_timestamp
      if condition
        condition.update_attribute(:updated_at, Time.now)
      end
    end
end
