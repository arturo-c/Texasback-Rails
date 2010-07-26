class MediaLogo < ActiveRecord::Base
  has_attachment :max_size => 2.megabytes,
                  :storage => :file_system, 
                  :path_prefix => 'public/_images/news_and_media',
                  :partition => false,
                  :content_type => :image,
                  :resize_to => "114>"
  
  validates_presence_of :filename
  validates_uniqueness_of :filename
  
  named_scope :all, :order => 'name'
  
  has_many :media_entries
  
  before_save :set_name
  
  protected
    def set_name
      self.name = ActiveSupport::Inflector.titleize(self.filename)
    end
end
