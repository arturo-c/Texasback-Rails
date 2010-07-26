class AskDoctorEntry < ActiveRecord::Base
  validates_presence_of :email, :subject, :content
end
