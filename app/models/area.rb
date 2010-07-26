class Area < ActiveRecord::Base
  validates_presence_of :name, :photo_path
  
  has_many :condition_versions
end
