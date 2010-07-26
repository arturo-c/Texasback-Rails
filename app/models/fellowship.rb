class Fellowship < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  
  named_scope :all, :order => 'name'
end
