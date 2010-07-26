class PressRelease < ActiveRecord::Base
  validates_presence_of :name, :release_date
  
  belongs_to :file_upload
  
  named_scope :all, :order => 'release_date DESC'
  named_scope :active, :conditions => { :active_flag => true }, :order => 'release_date DESC'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'release_date DESC'
  
  def active?
    self.active_flag
  end
  
  def has_file?
    !!self.file_upload
  end
  
  def file_name
    if self.file_upload
      self.file_upload.public_filename
    else
      ""
    end
  end
end
