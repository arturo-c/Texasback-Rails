class Team < ActiveRecord::Base
  validates_presence_of :name
  
  has_and_belongs_to_many :doctors, :join_table => 'doctor_teams', :class_name => 'Doctor', :uniq => true
  
  named_scope :all, :order => 'display_order'
  named_scope :with_published_doctors, lambda { { :include => { :doctors => :versions }, 
                                        :conditions => [ "doctor_versions.content_status_id = ? AND doctors.active_flag = ?", ContentStatus[:published].id, true ],
                                        :order => "teams.display_order, doctors.display_order" } }
                                      
                                        
  class << self
    def with_locations
      Team.find_by_sql("SELECT t.id, t.name, COUNT(1) as doctors
          FROM teams t,  doctor_teams dt, doctors d, doctor_versions dv
         WHERE dt.team_id = t.id
             AND d.id = dt.doctor_id
            AND dv.doctor_id = d.id
           AND dv.content_status_id = 2
           AND d.active_flag = 1
           AND (SELECT count(1) FROM doctor_locations dl WHERE dl.doctor_id = d.id > 0)
      GROUP BY t.id, t.name
      ORDER BY t.display_order")
    end
    
    def json_list
      result = {}
      
      Team.all.each do |team|
        result[team.id] = { :name => team.name }
      end
      
      result.to_json
    end
  end                                    
end
