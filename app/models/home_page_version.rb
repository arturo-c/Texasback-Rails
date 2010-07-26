class HomePageVersion < ActiveRecord::Base
  validates_presence_of :content_status_id, :page_title, :news_content, :news_link, :wellness_content, :wellness_link, :research_content, :research_link, :testimonials_content, :testimonials_link, :events_content, :events_link, :conditions_content
  validates_length_of :news_content, :maximum => 205
  validates_length_of :wellness_content, :maximum => 200 
  validates_length_of :research_content, :maximum => 220
  validates_length_of :testimonials_content, :maximum => 200
  validates_length_of :events_content, :maximum => 206
  validates_length_of :conditions_content, :maximum => 167
  
  def animation
    @animation ||= HomePageAnimation.active
  end
  
  # Returns a hash of the active images
  def images
    @images ||= {
      :news => HomePageImage.path_for_slot(:news),
      :wellness => HomePageImage.path_for_slot(:wellness),
      :research => HomePageImage.path_for_slot(:research),
      :testimonials => HomePageImage.path_for_slot(:testimonials),
      :conditions => HomePageImage.path_for_slot(:conditions),
      :events => HomePageImage.path_for_slot(:events)
    }
  end
end
