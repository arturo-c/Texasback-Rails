class ResearchTopic < ActiveRecord::Base
  has_many :versions, :class_name => 'ResearchTopicVersion'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40
  has_and_belongs_to_many :abstracts, :join_table => 'abstract_topics', :class_name => 'ResearchTopic', :uniq => true
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'research_topics.display_order'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'research_topics.display_order'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND research_topic_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'research_topics.display_order' } }
  
  # returns the current published version for this topic
  def published
    @published_version ||= ResearchTopicVersion.find_by_research_topic_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this topic
  def draft
    @draft_version ||= ResearchTopicVersion.find_by_research_topic_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
      @draft_version = ResearchTopicVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the research_topic_version is the research_topic_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:research_topic_id))
          if self.save
            self.draft.research_topic_id = self.id

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
        self.errors.add attribute, msg unless attribute == "research_topic_id"        
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
        @draft_version = ResearchTopicVersion.new :research_topic_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_id(id)
    topic = ResearchTopic.find_by_active_flag_and_id(true, id)
    
    if topic
      if topic.has_published?
        topic
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.find_active_published_by_slug(slug)
    topic = ResearchTopic.find_by_active_flag_and_slug(true, slug)
    
    if topic
      if topic.has_published?
        topic
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    ResearchTopic.find_by_sql(["
        SELECT t.*
          FROM research_topics t 
     LEFT JOIN research_topic_versions p ON (t.id = p.research_topic_id AND p.content_status_id = ?)
     LEFT JOIN research_topic_versions d ON (t.id = d.research_topic_id AND d.content_status_id = ?)
         WHERE t.active_flag = ?
      GROUP BY t.id, t.name
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY t.name", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  # returns all published abstracts with this topic_id
  def published_abstracts
    @published_abstracts ||= Abstract.find_all_published_with_topic(self.id)
  end
  
  def has_published_abstracts?
    published_abstracts.length > 0
  end
  
  def update_attributes_with_draft(attributes)
    self.attributes = attributes
    save_with_draft
  end
end
