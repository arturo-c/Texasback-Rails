class Treatment < ActiveRecord::Base
  validates_presence_of :name, :treatment_type_id
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40
  
  has_many :versions, :class_name => 'TreatmentVersion'  
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  belongs_to :treatment_type
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'treatments.display_order'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'treatments.display_order'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND treatment_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'treatments.display_order' } }
  named_scope :by_type, lambda { |type_id| { :conditions => [ "treatments.treatment_type_id = ?", type_id ], :include => :versions, :order => 'treatments.display_order' } }
  named_scope :by_type_or_parent, lambda { |type_id| { :conditions => [ "(treatments.treatment_type_id = ? OR treatment_types.parent_id = ?)", type_id, type_id ], :include => :treatment_type, :order => 'treatments.display_order' } }
  named_scope :by_exact_name, lambda { |name| { :conditions => [ "LOWER(name) = ?", name.to_s.downcase ] } }
  named_scope :matching, lambda { |query| { :conditions => [ "name LIKE ? OR treatment_versions.full_description LIKE ?", "%#{query.to_s}%", "%#{query.to_s}%" ] } }
  
  # returns the current published version for this treatment
  def published
    @published_version ||= TreatmentVersion.find_by_treatment_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this treatment
  def draft
    @draft_version ||= TreatmentVersion.find_by_treatment_id_and_content_status_id(self.id, ContentStatus[:draft].id)
  end
  
  def has_published?
    !published.nil?
  end
  
  def has_unpublished?
    has_draft? || !has_published?
  end
  
  def has_draft?
    !draft.nil?
  end
  
  def modified?
    self.updated_at > self.created_at
  end
    
  def type
    if self.treatment_type.parent
      self.treatment_type.parent
    else
      self.treatment_type
    end
  end
  
  # used for mass assignment of new/edit treatment forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = TreatmentVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the treatment_version is the treatment_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:treatment_id))
          if self.save
            self.draft.treatment_id = self.id

            if self.draft.save
              return true            
            end
          end
        end
      end
    end
    
    if self.draft
      self.draft.valid? 
      
      # load any draft errors
      self.draft.errors.each do |attribute, msg|        
        self.errors.add attribute, msg unless attribute == "treatment_id"        
      end
    end
    
    return false
  end
  
  # creates a new draft version for this treatment, copies a published version if one exists, otherwise starts as blank
  def create_draft
    unless has_draft?
      if has_published?
        @draft_version = self.published.clone
      else
        @draft_version = TreatmentVersion.new :treatment_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_id(id)
    treatment = Treatment.find_by_active_flag_and_id(true, id)
    
    if treatment
      if treatment.has_published?
        treatment
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.find_active_published_by_slug(slug)
    treatment = Treatment.find_by_active_flag_and_slug(true, slug)
    
    if treatment
      if treatment.has_published?
        treatment
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    Treatment.find_by_sql(["
        SELECT t.*
          FROM treatments t 
     LEFT JOIN treatment_versions p ON (t.id = p.treatment_id AND p.content_status_id = ?)
     LEFT JOIN treatment_versions d ON (t.id = d.treatment_id AND d.content_status_id = ?)
         WHERE t.active_flag = ?
      GROUP BY t.id, t.name
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY t.name", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  def update_attributes_with_draft(attributes)
    self.attributes = attributes
    save_with_draft
  end
end