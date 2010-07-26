class Term < ActiveRecord::Base
  has_many :versions, :class_name => 'TermVersion'  
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  belongs_to :term_group
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'name'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'name'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND term_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'name' } }
  named_scope :by_group, lambda { |group_id| { :conditions => [ "term_group_id = ?", group_id ], :order => 'name' } }
  
  validates_presence_of :name, :term_group_id
  validates_uniqueness_of :name
  
  before_validation :set_group_id
  
  # returns the current published version for this topic
  def published
    @published_version ||= TermVersion.find_by_term_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this topic
  def draft
    @draft_version ||= TermVersion.find_by_term_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
  
  # used for mass assignment of new/edit topic forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = TermVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the version is the term_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:term_id))
          if self.save
            self.draft.term_id = self.id

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
        self.errors.add attribute, msg unless attribute == "term_id"        
      end
    end
    
    return false
  end
  
  # creates a new draft version for this topic, copies a published version if one exists, otherwise starts as blank
  def create_draft
    unless has_draft?
      if has_published?
        @draft_version = self.published.clone
      else
        @draft_version = TermVersion.new :term_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def update_attributes_with_draft(attributes)
    self.attributes = attributes
    save_with_draft
  end
  
  protected
    def set_group_id
      self.term_group_id = TermGroup.find_by_term_name(self.name).id
    end
end
