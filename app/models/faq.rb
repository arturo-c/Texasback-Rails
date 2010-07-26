class Faq < ActiveRecord::Base
  has_many :versions, :class_name => 'FaqVersion'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User' 
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'display_order'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'display_order'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND faq_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'display_order' } }
  
  # name returns the current published question 
  def name
    if self.has_published?
      self.published.question
    elsif self.has_draft?
      self.draft.question
    else
      ""
    end
  end
  
  # returns the current published version for this condition
  def published
    @published_version ||= FaqVersion.find_by_faq_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this condition
  def draft
    @draft_version ||= FaqVersion.find_by_faq_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
  
  # used for mass assignment of new/edit forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = FaqVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the version is the faq_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:faq_id))
          if self.save
            self.draft.faq_id = self.id

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
        self.errors.add attribute, msg unless attribute == "faq_id"        
      end
    end
    
    return false
  end
  
  # creates a new draft version for this item, copies a published version if one exists, otherwise starts as blank
  def create_draft
    unless has_draft?
      if has_published?
        @draft_version = self.published.clone
      else
        @draft_version = FaqVersion.new :faq_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.not_published
    Faq.find_by_sql(["
        SELECT a.*
          FROM faqs a 
     LEFT JOIN faq_versions p ON (a.id = p.faq_id AND p.content_status_id = ?)
     LEFT JOIN faq_versions d ON (a.id = d.faq_id AND d.content_status_id = ?)
         WHERE a.active_flag = ?
      GROUP BY a.id
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY a.display_order", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  def update_attributes_with_draft(attributes)
    self.attributes = attributes
    save_with_draft
  end
end
