class Condition < ActiveRecord::Base
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40
  
  has_many :versions, :class_name => 'ConditionVersion'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  has_and_belongs_to_many :reviews, :join_table => 'review_conditions', :class_name => 'Review', :uniq => true
  has_many :images, :class_name => 'ConditionImage'
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'display_order'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'display_order'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND condition_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'display_order' } }
  named_scope :by_exact_name, lambda { |name| { :conditions => [ "LOWER(name) = ?", name.to_s.downcase ] } }
  named_scope :matching, lambda { |query| { :conditions => [ "name LIKE ? OR condition_versions.full_description LIKE ?", "%#{query.to_s}%", "%#{query.to_s}%" ] } }
  
  # returns the current published version for this condition
  def published
    @published_version ||= ConditionVersion.find_by_condition_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this condition
  def draft
    @draft_version ||= ConditionVersion.find_by_condition_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
  
  def has_published_reviews?
    published_reviews.length > 0
  end
  
  def published_reviews
    @published_reviews ||= Review.find_all_published_with_condition(self.id)
  end  
  
  def featured_review
    unless @featured_review
      if self.has_published_reviews?
        if self.featured_review_id.to_i > 0
          @featured_review = Review.find(self.featured_review_id)
        end
        
        if @featured_review.nil? or (!@featured_review.has_published?)          
          @featured_review = self.published_reviews[rand(self.published_reviews.length)]
        end
      else
        @featured_review = nil
      end
    end
    
    @featured_review
  end
  
  # used for mass assignment of new/edit condition forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = ConditionVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the condition_version is the condition_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:condition_id))
          if self.save
            self.draft.condition_id = self.id

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
        self.errors.add attribute, msg unless attribute == "condition_id"        
      end
    end
    
    return false
  end
  
  # creates a new draft version for this condition, copies a published version if one exists, otherwise starts as blank
  def create_draft
    unless has_draft?
      if has_published?
        @draft_version = self.published.clone
        @draft_version.treatment_ids = self.published.treatment_ids
        @draft_version.images = self.published.image_ids
      else
        @draft_version = ConditionVersion.new :condition_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_slug(slug)
    condition = Condition.find_by_active_flag_and_slug(true, slug)
    
    if condition
      if condition.has_published?
        condition
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    Condition.find_by_sql(["
        SELECT c.*
          FROM conditions c 
     LEFT JOIN condition_versions p ON (c.id = p.condition_id AND p.content_status_id = ?)
     LEFT JOIN condition_versions d ON (c.id = d.condition_id AND d.content_status_id = ?)
         WHERE c.active_flag = ?
      GROUP BY c.id, c.name
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY c.name", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  def update_attributes_with_draft(attributes)
    self.attributes = attributes
    save_with_draft
  end
  
  def has_images?
    self.images.length > 0
  end
end
