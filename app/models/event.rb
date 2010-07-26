class Event < ActiveRecord::Base
  has_many :versions, :class_name => 'EventVersion'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  
  has_and_belongs_to_many :topics, :join_table => 'events_topics', :class_name => 'EventTopic', :uniq => true
  has_many :images, :class_name => 'EventImage'
  
  after_save :save_topics  
  
  validates_presence_of :event_date, :name
  validates_date :event_date, :after => '1 Jan 1900'
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'event_date'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'event_date'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND event_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'event_date' } }
  named_scope :by_month, lambda { |date| { :conditions => [ "MONTH(event_date) = ? AND YEAR(event_date) = ?", date.month, date.year ], :order => 'event_date' } }
  named_scope :upcoming, lambda { { :conditions => [ "event_date > ?", Date.today ], :order => 'event_date', :limit => 5 } }
  
  def event_hour
    if self.event_date
      hour = self.event_date.hour

      if hour > 12
        hour = hour - 12
      elsif hour == 0
        hour = 12
      end

      hour
    else 
      12
    end    
  end
  
  def event_minute
    if self.event_date
      self.event_date.min
    else
      0
    end
  end
  
  def event_ampm
    if self.event_date
      self.event_date.hour >= 12 ? "PM" : "AM"
    else
      'AM'
    end 
  end
  
  # returns the current published version for this condition
  def published
    @published_version ||= EventVersion.find_by_event_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this condition
  def draft
    @draft_version ||= EventVersion.find_by_event_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
  
  def has_topics?
    self.topics.length > 0
  end
  
  # used for mass assignment of new/edit forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = EventVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the version is the event_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:event_id))
          if self.save
            self.draft.event_id = self.id

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
        self.errors.add attribute, msg unless attribute == "event_id"        
      end
    end
    
    return false
  end
  
  # creates a new draft version for this item, copies a published version if one exists, otherwise starts as blank
  def create_draft
    unless has_draft?
      if has_published?
        @draft_version = self.published.clone
        @draft_version.images = self.published.image_ids
      else
        @draft_version = EventVersion.new :event_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_slug(slug)
    the_event = Event.find_by_active_flag_and_slug(true, slug)
    
    if the_event
      if the_event.has_published?
        the_event
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    Event.find_by_sql(["
        SELECT a.*
          FROM events a 
     LEFT JOIN event_versions p ON (a.id = p.event_id AND p.content_status_id = ?)
     LEFT JOIN event_versions d ON (a.id = d.event_id AND d.content_status_id = ?)
         WHERE a.active_flag = ?
      GROUP BY a.id
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY a.event_date", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  def self.find_all_with_topic(topic_id)
    topic_id = topic_id.to_i
    
    sql = []
    
    sql << "SELECT a.* FROM events a"
    
    if topic_id > 0
      sql << sanitize_sql([ "LEFT JOIN events_topics t ON (a.id = t.event_id AND t.event_topic_id = ?)", topic_id ])
    else
      sql << "LEFT JOIN events_topics t ON (a.id = t.event_id)"
    end
    
    sql << "WHERE active_flag = 1"
        
    sql << "GROUP BY a.id"
    sql << "HAVING count(t.event_id) > 0"
    sql << "ORDER BY a.event_date"
    
    Event.find_by_sql(sql.join("\n"))
  end
  
  def self.published_upcoming_with_topic(topic_id)
    topic_id = topic_id.to_i
    
    sql = []
    
    sql << "SELECT a.*"
    sql << "FROM events a"
    
    if topic_id > 0
      sql << sanitize_sql([ "LEFT JOIN events_topics t ON (a.id = t.event_id AND t.event_topic_id = ?)", topic_id ])
    end    
    
    sql << sanitize_sql([ "JOIN event_versions v ON (a.id = v.event_id AND v.content_status_id = ?)", ContentStatus[:published].id ])
    sql << sanitize_sql([ "WHERE active_flag = ?", true ]) 
    sql << sanitize_sql([ "AND a.event_date > ?", Time.today ])
    sql << "GROUP BY a.id"
    sql << "HAVING count(t.event_id) > 0"
    sql << "ORDER BY a.event_date"
    
    Event.find_by_sql(sql.join("\n"))
  end
  
  def self.find_all_without_topics
    Event.find_by_sql("
      SELECT a.*
        FROM events a
   LEFT JOIN events_topics t ON (a.id = t.event_id)
    GROUP BY a.id
      HAVING COUNT(t.event_id) < 1
    ORDER BY a.event_date")
  end
  
  def self.find_all_published_with_topic(topic_id)
    Event.find_by_sql(["
    SELECT a.*
     FROM events a
     JOIN events_topics t ON (t.event_topic_id = ? AND a.id = t.event_id)
     JOIN event_versions v ON (a.id = v.event_id AND v.content_status_id = ?)
    WHERE a.active_flag = ?
    ORDER BY a.event_date", topic_id, ContentStatus[:published].id, true ])
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
    self['topic_ids_set'] ||= self.topics.collect { |t| t.id }
  end
  
  def has_images?
    self.images.length > 0
  end
  
  protected
    def save_topics
      if @topic_ids_set
        self.topics.clear
      
        self.topic_ids.each do |id|
          the_new_topic = EventTopic.find(id)
        
          if the_new_topic
            if the_new_topic.has_published?
              self.topics << the_new_topic
            end
          end
        end
      end
    end
end
