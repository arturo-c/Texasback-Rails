class EventVersionImage < ActiveRecord::Base
  validates_presence_of :event_version_id, :event_image_id
  
  belongs_to :event_version
  belongs_to :event_image
end
