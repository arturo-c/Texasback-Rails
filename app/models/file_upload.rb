class FileUpload < ActiveRecord::Base
  has_attachment :max_size => 10.megabytes,
                  :storage => :file_system, 
                  :path_prefix => 'public/_docs',
                  :partition => false
  
  validates_uniqueness_of :filename
  validates_presence_of :filename
  
  has_many :press_releases
  
  named_scope :all, :order => 'filename'  
end
