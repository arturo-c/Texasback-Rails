class EventVersion < ActiveRecord::Base
  belongs_to :event
  belongs_to :content_status
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  has_many :event_version_images, :dependent => :delete_all, :order => 'position'
  
  validates_presence_of :event_id, :content_status_id, :location, :short_description, :full_description
  validates_length_of :short_description, :maximum => 300
  
  after_save :save_images
  
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
    if draft? && self.event
      existing_published_version = self.event.published
      
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
  
  def image_ids
    @image_ids ||= self.event_version_images.collect(&:event_image_id)
  end
  
  def images
    @images ||= EventImage.find(image_ids)
  end
  
  def images=(image_ids)
    @image_ids = image_ids    
    @images = nil
    
    @modified_images = true    
  end
  
  def has_images?
    self.image_ids.length > 0
  end
  
  protected
    def validate
      # if this page is draft or published, there can be no other versions of that status      
      if self.draft?
        other_versions = find_other_by_event_id_and_status(self.event_id, ContentStatus[:draft].id)
        
        errors.add :content_status_id, 'is already taken for this event' if other_versions.length > 0
      end
      
      if self.published?
        other_versions = find_other_by_event_id_and_status(self.event_id, ContentStatus[:published].id)
        
        errors.add :content_status_id, 'is already taken for this event' if other_versions.length > 0
      end
    end
    
    def find_other_by_event_id_and_status(event_id, content_status_id)
      if self.new_record?
        EventVersion.find_all_by_event_id_and_content_status_id(event_id, content_status_id)
      else
        EventVersion.find(:all, :conditions => [ "event_id = ? AND content_status_id = ? AND id <> ?", event_id, content_status_id, self.id ])
      end
    end
    
    def save_images
      if @modified_images
        self.event_version_images.clear
        
        @image_ids.each_with_index do |image_id, index|
          i = EventVersionImage.new(:event_version_id => self.id, :event_image_id => image_id, :position => index)
          i.save
        end
      end
    end
end
