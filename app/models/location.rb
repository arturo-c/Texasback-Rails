class Location < ActiveRecord::Base
  validates_presence_of :name, :address, :city, :state, :zip, :phone, :map_link
  
  named_scope :all, :order => 'state DESC, display_order ASC'
  named_scope :by_state, lambda { |state| { :conditions => [ "state = ?", state ], :order => 'display_order ASC' } }

  def name_and_state
    "#{name.strip}, #{state.strip.upcase}"
  end
  
  def doctors
    @doctors ||= Doctor.published_with_location(self.id)
  end
  
  def doctors_on_team(team_id)
    Doctor.published_with_location_and_team(self.id, team_id).count
  end
  
  def doctor_breakdown
    unless @doctor_breakdown
      @doctor_breakdown = {}
    
      Team.all.each do |team|
        @doctor_breakdown[team.id.to_s] = doctors_on_team(team.id)
      end
    end
    
    @doctor_breakdown
  end
  
  def to_json
    { :name => self.name, 
      :id => self.id, 
      :coordinates => [ self.latitude, self.longitude ],
      :state => self.state }.to_json
  end
  
  class << self
    # returns a json list of locations for use on google maps
    def json_list
      locations = Location.all
      
      locations = locations.collect do |location|
        { :name => location.name, 
          :id => location.id, 
          :coordinates => [ location.latitude, location.longitude ],
          :doctors => location.doctor_breakdown,
          :state => location.state }
      end
      
      locations.to_json
    end
  end
end
