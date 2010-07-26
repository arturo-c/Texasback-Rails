class Diagnostic < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40
  
  has_many :versions, :class_name => 'DiagnosticVersion'  
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'diagnostics.display_order'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'diagnostics.display_order'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND diagnostic_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'diagnostics.display_order' } }
  
  # returns the current published version for this diagnostic
  def published
    @published_version ||= DiagnosticVersion.find_by_diagnostic_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this diagnostic
  def draft
    @draft_version ||= DiagnosticVersion.find_by_diagnostic_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
  
  # used for mass assignment of new/edit diagnostic forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = DiagnosticVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the diagnostic_version is the diagnostic_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:diagnostic_id)) || self.draft.errors.length == 0
          if self.save
            self.draft.diagnostic_id = self.id

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
        self.errors.add attribute, msg unless attribute == "diagnostic_id"        
      end
    end
    
    return false
  end
  
  # creates a new draft version for this diagnostic, copies a published version if one exists, otherwise starts as blank
  def create_draft
    unless has_draft?
      if has_published?
        @draft_version = self.published.clone
      else
        @draft_version = DiagnosticVersion.new :diagnostic_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_id(id)
    diagnostic = Diagnostic.find_by_active_flag_and_id(true, id)
    
    if diagnostic
      if diagnostic.has_published?
        diagnostic
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.find_active_published_by_slug(slug)
    diagnostic = Diagnostic.find_by_active_flag_and_slug(true, slug)
    
    if diagnostic
      if diagnostic.has_published?
        diagnostic
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    Diagnostic.find_by_sql(["
        SELECT t.*
          FROM diagnostics t 
     LEFT JOIN diagnostic_versions p ON (t.id = p.diagnostic_id AND p.content_status_id = ?)
     LEFT JOIN diagnostic_versions d ON (t.id = d.diagnostic_id AND d.content_status_id = ?)
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
