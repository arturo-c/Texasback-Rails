class Review < ActiveRecord::Base  
  validates_presence_of :first_name, :last_name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40  
  
  has_many :versions, :class_name => 'ReviewVersion'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  has_and_belongs_to_many :conditions, :join_table => 'review_conditions', :class_name => 'Condition', :uniq => true
  has_and_belongs_to_many :treatments, :join_table => 'review_treatments', :class_name => 'Treatment', :uniq => true
  
  after_save :save_conditions
  after_save :save_treatments
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'last_name, first_name'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'last_name, first_name'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND review_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'last_name, first_name' } }
  
  def name
    "#{self.first_name} #{self.last_name}"
  end
  
  def first_initial
    if self.first_name.length > 0
      self.first_name.split(//)[0].upcase
    else
      ""
    end
  end
  
  def last_initial
    if self.last_name.length > 0
      self.last_name.split(//)[0].upcase
    else
      ""
    end
  end
  
  # last name, first initial
  def abbrev_name
    "#{self.last_name}, #{self.first_initial}."
  end
  
  # returns the current published version for this condition
  def published
    @published_version ||= ReviewVersion.find_by_review_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this condition
  def draft
    @draft_version ||= ReviewVersion.find_by_review_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
  
  # used for mass assignment of new/edit review forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = ReviewVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the review_version is the review_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:review_id))
          if self.save
            self.draft.review_id = self.id

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
        self.errors.add attribute, msg unless attribute == "review_id"        
      end
    end
    
    return false
  end
  
  # creates a new draft version for this review, copies a published version if one exists, otherwise starts as blank
  def create_draft
    unless has_draft?
      if has_published?
        @draft_version = self.published.clone
      else
        @draft_version = ReviewVersion.new :review_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_slug(slug)
    review = Review.find_by_active_flag_and_slug(true, slug)
    
    if review
      if review.has_published?
        review
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    Review.find_by_sql(["
        SELECT r.*
          FROM reviews r
     LEFT JOIN review_versions p ON (r.id = p.review_id AND p.content_status_id = ?)
     LEFT JOIN review_versions d ON (r.id = d.review_id AND d.content_status_id = ?)
         WHERE r.active_flag = ?
      GROUP BY r.id, r.last_name, r.first_name
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY last_name, first_name", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  def self.find_all_with_condition(condition_id)    
    condition_id = condition_id.to_i
    
    sql = []
    
    sql << "SELECT r.* FROM reviews r"
    
    if condition_id > 0
      sql << sanitize_sql([ "LEFT JOIN review_conditions c ON (r.id = c.review_id AND c.condition_id = ?)", condition_id ])
    else
      sql << "LEFT JOIN review_conditions c ON (r.id = c.review_id)"
    end
    
    sql << "WHERE r.active_flag = 1"        
    sql << "GROUP BY r.id, r.last_name, r.first_name"
    sql << "HAVING count(c.review_id) > 0"
    sql << "ORDER BY last_name, first_name"
    
    Review.find_by_sql(sql.join("\n"))
  end
  
  def self.find_all_without_conditions
    Review.find_by_sql("
      SELECT r.*
        FROM reviews r
   LEFT JOIN review_conditions c ON (r.id = c.review_id)
    GROUP BY r.id, r.first_name, r.last_name
      HAVING COUNT(c.review_id) < 1
    ORDER BY last_name, first_name")
  end
  
  def self.find_all_published_with_condition(condition_id)
    Review.find_by_sql(["
    SELECT r.*
     FROM reviews r
     JOIN review_conditions t ON (t.condition_id = ? AND r.id = t.review_id)
     JOIN review_versions v ON (r.id = v.review_id AND v.content_status_id = ?)
    WHERE r.active_flag = ?
    ORDER BY last_name, first_name", condition_id, ContentStatus[:published].id, true ])
  end
  
  def update_attributes_with_draft(attributes)
    self.attributes = attributes
    save_with_draft
  end
  
  # mass assignment of condition ids array, doesn't save this until we've validated
  def condition_ids=(the_ids)
    self['condition_ids_set'] = the_ids.to_a.collect { |i| i.to_i }
    
    @condition_ids_set = true
  end
  
  def condition_ids
    self['condition_ids_set'] ||= self.conditions.collect(&:id)
  end
  
  def treatment_ids=(the_ids)
    self['treatment_ids_set'] = the_ids.to_a.collect { |i| i.to_i }
    
    @treatment_ids_set = true
  end
  
  def treatment_ids
    self['treatment_ids_set'] ||= self.treatments.collect(&:id)
  end
  
  protected
    def save_conditions
      if @condition_ids_set
        self.conditions.clear
      
        self.condition_ids.each do |id|
          the_new_condition = Condition.find(id)
        
          if the_new_condition
            if the_new_condition.has_published?
              self.conditions << the_new_condition
            end
          end
        end
      end
    end
    
    def save_treatments
      if @treatment_ids_set
        self.treatments.clear
      
        self.treatment_ids.each do |id|
          the_new_treatment = Treatment.find(id)
        
          if the_new_treatment
            if the_new_treatment.has_published?
              self.treatments << the_new_treatment
            end
          end
        end
      end
    end
end
