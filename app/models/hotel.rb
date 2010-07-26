class Hotel < ActiveRecord::Base
  validates_presence_of :name
  
  named_scope :all, :order => 'display_order'
  named_scope :active, :conditions => { :active_flag => true }, :order => 'display_order'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'display_order'
  named_scope :preferred, :conditions => { :preferred_flag => true, :active_flag => true }, :order => 'display_order'
  named_scope :not_preferred, :conditions => { :preferred_flag => false, :active_flag => true }, :order => 'display_order'
  
  def preferred?
    self.preferred_flag
  end
  
  def active?
    self.active_flag
  end
end
