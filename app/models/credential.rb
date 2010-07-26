class Credential < ActiveRecord::Base
  validates_presence_of :name, :display_order
  
  named_scope :all, :order => 'display_order'
end
