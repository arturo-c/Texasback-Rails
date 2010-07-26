class HomePageAnimation < ActiveRecord::Base
  validates_presence_of :title, :path
  
  def self.active
    HomePageAnimation.find_by_active(true)
  end
end
