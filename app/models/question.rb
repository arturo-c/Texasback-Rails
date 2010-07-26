class Question < ActiveRecord::Base
  has_many :versions, :class_name => 'QuestionVersion'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  
  validates_presence_of :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40
  has_and_belongs_to_many :topics, :join_table => 'questions_topics', :class_name => 'QuestionTopic', :uniq => true
  
  after_save :save_topics  
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'display_order'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'display_order'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND question_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'display_order' } }
  
  # name returns the current published question 
  def name
    if self.has_published?
      self.published.the_question
    elsif self.has_draft?
      self.draft.the_question
    else
      ""
    end
  end
  
  # returns the current published version for this condition
  def published
    @published_version ||= QuestionVersion.find_by_question_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this condition
  def draft
    @draft_version ||= QuestionVersion.find_by_question_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
      @draft_version = QuestionVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the version is the question_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:question_id))
          if self.save
            self.draft.question_id = self.id

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
        self.errors.add attribute, msg unless attribute == "question_id"        
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
        @draft_version = QuestionVersion.new :question_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_slug(slug)
    the_question = Question.find_by_active_flag_and_slug(true, slug)
    
    if the_question
      if the_question.has_published?
        the_question
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    Question.find_by_sql(["
        SELECT a.*
          FROM questions a 
     LEFT JOIN question_versions p ON (a.id = p.question_id AND p.content_status_id = ?)
     LEFT JOIN question_versions d ON (a.id = d.question_id AND d.content_status_id = ?)
         WHERE a.active_flag = ?
      GROUP BY a.id
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY a.display_order", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  def self.find_all_with_topic(topic_id)
    topic_id = topic_id.to_i
    
    sql = []
    
    sql << "SELECT a.* FROM questions a"
    
    if topic_id > 0
      sql << sanitize_sql([ "LEFT JOIN questions_topics t ON (a.id = t.question_id AND t.question_topic_id = ?)", topic_id ])
    else
      sql << "LEFT JOIN questions_topics t ON (a.id = t.question_id)"
    end
    
    sql << "WHERE active_flag = 1"
        
    sql << "GROUP BY a.id"
    sql << "HAVING count(t.question_id) > 0"
    sql << "ORDER BY a.display_order"
    
    Question.find_by_sql(sql.join("\n"))
  end
  
  def self.find_all_without_topics
    Question.find_by_sql("
      SELECT a.*
        FROM questions a
   LEFT JOIN questions_topics t ON (a.id = t.question_id)
    GROUP BY a.id
      HAVING COUNT(t.question_id) < 1
    ORDER BY a.display_order")
  end
  
  def self.find_all_published_with_topic(topic_id)
    Question.find_by_sql(["
    SELECT a.*
     FROM questions a
     JOIN questions_topics t ON (t.question_topic_id = ? AND a.id = t.question_id)
     JOIN question_versions v ON (a.id = v.question_id AND v.content_status_id = ?)
    WHERE a.active_flag = ?
    ORDER BY a.display_order", topic_id, ContentStatus[:published].id, true ])
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
        errors.add :topic_ids, 'You must choose at least one topic'
      end
    end
  
    def save_topics
      if @topic_ids_set
        self.topics.clear
      
        self.topic_ids.each do |id|
          the_new_topic = QuestionTopic.find(id)
        
          if the_new_topic
            if the_new_topic.has_published?
              self.topics << the_new_topic
            end
          end
        end
      end
    end
end
