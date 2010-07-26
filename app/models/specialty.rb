class Specialty < ActiveRecord::Base
  validates_presence_of :name
  has_many :doctors, :order => 'hire_date'
  
  named_scope :all, :order => 'name'
  named_scope :with_published_doctors, lambda { { :include => { :doctors => :versions }, 
                                        :conditions => [ "doctor_versions.content_status_id = ?", ContentStatus[:published].id ],
                                        :order => "specialties.name, doctors.display_order" } }
end
