class Abstract < ActiveRecord::Base
  validates_presence_of :name, :slug, :publish_date
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40
  validates_format_of :link, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix, :message => "isn't a valid URL format."
  validates_date :publish_date, :after => '1 Jan 1900'
  
  has_many :versions, :class_name => 'AbstractVersion'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  has_and_belongs_to_many :topics, :join_table => 'abstract_topics', :class_name => 'ResearchTopic', :uniq => true
  
  after_save :save_topics
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'publish_date DESC'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'publish_date DESC'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND abstract_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'publish_date DESC' } }
  
  # returns the current published version for this condition
  def published
    @published_version ||= AbstractVersion.find_by_abstract_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this condition
  def draft
    @draft_version ||= AbstractVersion.find_by_abstract_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
  
  def publish_year
    self.publish_date.is_a?(Date) ? self.publish_date.year.to_s : ''
  end
  
  def publish_month
    self.publish_date.is_a?(Date) ? self.publish_date.strftime("%B") : ''
  end
  
  # used for mass assignment of new/edit abstract forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = AbstractVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the abstract_version is the abstract_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:abstract_id))
          if self.save
            self.draft.abstract_id = self.id

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
        self.errors.add attribute, msg unless attribute == "abstract_id"        
      end
    end
    
    return false
  end
  
  # creates a new draft version for this abstract, copies a published version if one exists, otherwise starts as blank
  def create_draft
    unless has_draft?
      if has_published?
        @draft_version = self.published.clone
      else
        @draft_version = AbstractVersion.new :abstract_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_slug(slug)
    abstract = Abstract.find_by_active_flag_and_slug(true, slug)
    
    if abstract
      if abstract.has_published?
        abstract
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    Abstract.find_by_sql(["
        SELECT a.*
          FROM abstracts a 
     LEFT JOIN abstract_versions p ON (a.id = p.abstract_id AND p.content_status_id = ?)
     LEFT JOIN abstract_versions d ON (a.id = d.abstract_id AND d.content_status_id = ?)
         WHERE a.active_flag = ?
      GROUP BY a.id, a.name
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY a.publish_date DESC", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  def self.find_all_with_topic(topic_id)
    Abstract.find_all_with_topic_and_year(topic_id, nil)
  end
  
  def self.find_all_with_topic_and_year(topic_id, year)
    year = year.to_i
    topic_id = topic_id.to_i
    
    sql = []
    
    sql << "SELECT a.* FROM abstracts a"
    
    if topic_id > 0
      sql << sanitize_sql([ "LEFT JOIN abstract_topics t ON (a.id = t.abstract_id AND t.research_topic_id = ?)", topic_id ])
    else
      sql << "LEFT JOIN abstract_topics t ON (a.id = t.abstract_id)"
    end
    
    sql << "WHERE active_flag = 1"
    
    if year > 1900 && year < 2200
      sql << sanitize_sql([ "AND a.publish_date BETWEEN '?-01-01' AND '?-12-31'", year, year ])
    end
    
    sql << "GROUP BY a.id, a.name"
    sql << "HAVING count(t.abstract_id) > 0"
    sql << "ORDER BY a.publish_date DESC"
    
    Abstract.find_by_sql(sql.join("\n"))
  end
  
  def self.find_all_without_topics
    Abstract.find_by_sql("
      SELECT a.*
        FROM abstracts a
   LEFT JOIN abstract_topics t ON (a.id = t.abstract_id)
    GROUP BY a.id, a.name
      HAVING COUNT(t.abstract_id) < 1
    ORDER BY a.publish_date DESC")
  end
  
  def self.find_all_published_with_topic(topic_id)
    Abstract.find_by_sql(["
    SELECT a.*
     FROM abstracts a
     JOIN abstract_topics t ON (t.research_topic_id = ? AND a.id = t.abstract_id)
     JOIN abstract_versions v ON (a.id = v.abstract_id AND v.content_status_id = ?)
    WHERE a.active_flag = ?
    ORDER BY a.publish_date DESC", topic_id, ContentStatus[:published].id, true ])
  end
  
  def update_attributes_with_draft(attributes)
    self.attributes = attributes
    save_with_draft
  end
  
  # mass assignment of topic ids array, doesn't save this until we've validated
  def topic_ids=(the_ids)
    self['topic_ids_set'] = the_ids.to_a.collect { |i| i.to_i }
    
    @topic_ids_set = true
  end
  
  def topic_ids
    self['topic_ids_set'] || self.topics.collect { |t| t.id }
  end
  
  protected
    def validate
      if self.topic_ids.length == 0
        errors.add 'topic_ids', '^You must choose at least one topic'
      end
    end
  
    def save_topics
      if @topic_ids_set
        self.topics.clear
      
        self.topic_ids.each do |id|
          the_new_topic = ResearchTopic.find(id)
        
          if the_new_topic
            if the_new_topic.has_published?
              self.topics << the_new_topic
            end
          end
        end
      end
    end
end
