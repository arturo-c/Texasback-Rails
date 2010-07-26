class TreatmentType < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40
  
  has_many :treatments
  
  belongs_to :parent, :class_name => 'TreatmentType'
  
  named_scope :all, :order => 'display_order'
  named_scope :top_level, :conditions => "parent_id = 0", :order => 'display_order'
  
  def children
    TreatmentType.find_all_by_parent_id(self.id)
  end
  
  def top?
    self.parent_id == 0
  end
  
  def published_treatments
    @published ||= Treatment.all_published.by_type(self.id)
  end
  
  def has_published_treatments?
    published_treatments.length > 0
  end
  
  # includes child published treatments
  def all_published_treatments
    @all_published ||= Treatment.all_published.by_type_or_parent(self.id)
  end

  def active_treatments
    @active_treatments ||= Treatment.active.by_type(self.id)
  end
  
  # includes child active treatments
  def all_active_treatments
    @all_active_treatments ||= Treatment.active.by_type_or_parent(self.id)
  end
  
  def clean_name
    self.name.gsub("Treatments", "")
  end
end