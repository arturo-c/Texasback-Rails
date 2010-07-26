class EventImage < ActiveRecord::Base
  belongs_to :event
  
  has_attachment :content_type => :images, :thumbnails => { :thumb => "100>", :cropped => "450>" }, :storage => :file_system, :path_prefix => 'public/_images/events'
             
  attr_accessible :caption
  
  validate :check_content_type

  after_save :update_event_timestamp
                 
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

    def update_event_timestamp
      if event
       event.update_attribute(:updated_at, Time.now)
      end
    end
end