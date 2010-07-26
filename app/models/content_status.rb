class ContentStatus < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def self.[](value)
    self.find_by_name(value.to_s)
  end
end
