class Contact < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :zip, :question
  validates_length_of :first_name, :maximum => 30
  validates_length_of :last_name, :email, :city, :maximum => 50
  validates_length_of :phone, :maximum => 20
  validates_length_of :address1, :address2, :maximum => 70
  validates_length_of :state, :maximum => 2
  validates_length_of :zip, :maximum => 5
  validates_length_of :how_did_you_hear, :maximum => 250
end
