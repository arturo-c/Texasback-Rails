class Doctor < ActiveRecord::Base
  has_many :versions, :class_name => 'DoctorVersion'
  belongs_to :specialty
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  has_and_belongs_to_many :credentials, :join_table => 'doctor_credentials', :class_name => 'Credential', :uniq => true
  has_and_belongs_to_many :locations, :join_table => 'doctor_locations', :class_name => 'Location', :uniq => true
  has_and_belongs_to_many :teams, :join_table => 'doctor_teams', :class_name => 'Team', :uniq => true
  
  validates_presence_of :slug, :first_name, :last_name
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /^[A-Za-z0-9_]+$/, :message => "isn't valid.  (can only contain letters, numbers or underscores)"
  validates_length_of :slug, :minimum => 2
  validates_length_of :slug, :maximum => 40
  validates_date :hire_date, :after => '1 Jan 1900'
  
  belongs_to :publication, :class_name => 'FileUpload', :foreign_key => 'publications_file_id'
  
  after_save :save_credentials, :save_locations, :save_teams
  
  named_scope :active, :conditions => { :active_flag => true }, :order => 'display_order'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'display_order'
  named_scope :all_published, lambda { { :conditions => [ "active_flag = ? AND doctor_versions.content_status_id = ? ", true, ContentStatus[:published].id ], :include => :versions, :order => 'display_order' } }
  named_scope :published_by_name, lambda { { 
    :conditions => [ "active_flag = ? AND doctor_versions.content_status_id = ? ", true, ContentStatus[:published].id ], 
    :include => [ :versions, :specialty, :credentials, :locations, :teams ], 
    :order => 'last_name, first_name' } 
  }
  
  named_scope :published_with_location_and_team, lambda { |location_id, team_id| { 
    :include => [ :versions, :specialty, :credentials, :locations, :teams ],
    :order => 'doctors.display_order',
    :conditions => [ "active_flag = ? AND doctor_versions.content_status_id = ? AND doctor_locations.location_id = ? AND doctor_teams.team_id = ?", true, ContentStatus[:published].id, location_id, team_id ]
  }}
  
  named_scope :published_with_team, lambda { |team_id| { 
    :include => [ :versions, :specialty, :credentials, :locations, :teams ],
    :order => 'doctors.display_order',
    :conditions => [ "active_flag = ? AND doctor_versions.content_status_id = ? AND doctor_teams.team_id = ?", true, ContentStatus[:published].id, team_id ]
  }}
  
  named_scope :published_with_location, lambda { |location_id| { 
    :include => [ :versions, :specialty, :credentials, :locations, :teams ],
    :order => 'doctors.display_order',
    :conditions => [ "active_flag = ? AND doctor_versions.content_status_id = ? AND doctor_locations.location_id = ?", true, ContentStatus[:published].id, location_id ]
  }}
  
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
  
  # name with credentials after
  def full_name
    the_name = self.name
    
    if self.has_credentials?
      the_name << ", "      
      the_name << self.credentials.collect(&:name).join(", ")
    end
    
    if self.has_published?
      the_name << ", #{self.published.other_credentials}" unless self.published.other_credentials.blank?
    end
    
    the_name
  end
  
  # returns the current published version for this condition
  def published
    @published_version ||= DoctorVersion.find_by_doctor_id_and_content_status_id(self.id, ContentStatus[:published].id)
  end
  
  # returns the current draft version for this condition
  def draft
    @draft_version ||= DoctorVersion.find_by_doctor_id_and_content_status_id(self.id, ContentStatus[:draft].id)
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
  
  def has_credentials?
    self.credentials.length > 0
  end
  
  def has_locations?
    self.locations.length > 0
  end
  
  def has_teams?
    self.locations.length > 0
  end
  
  def hire_year
    self.hire_date.is_a?(Date) ? self.hire_date.year.to_s : ''
  end
  
  def hire_month
    self.hire_date.is_a?(Date) ? self.hire_date.strftime("%B") : ''
  end
  
  # used for mass assignment of new/edit forms
  def draft_version_attributes=(attributes)
    if self.draft
      @draft_version.attributes = attributes
      @draft_version.content_status_id = ContentStatus[:draft].id
    else
      @draft_version = DoctorVersion.new(attributes.merge(:content_status_id => ContentStatus[:draft].id))
    end
  end
  
  def save_with_draft  
    if self.draft
      if self.valid?
        # make sure the only error in the version is the doctor_id (or existing record)
        self.draft.valid?
        
        if !self.draft.new_record? || (self.draft.errors.length == 1 && self.draft.errors.invalid?(:doctor_id))
          if self.save
            self.draft.doctor_id = self.id

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
        self.errors.add attribute, msg unless attribute == "doctor_id"        
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
        @draft_version = DoctorVersion.new :doctor_id => self.id
      end
      
      @draft_version.content_status_id = ContentStatus[:draft].id
    end
    
    @draft_version
  end
  
  def self.find_active_published_by_slug(slug)
    doctor = Doctor.find_by_active_flag_and_slug(true, slug)
    
    if doctor
      if doctor.has_published?
        doctor
      else
        nil
      end
    else
      nil
    end
  end
  
  def self.not_published
    Doctor.find_by_sql(["
        SELECT a.*
          FROM doctors a 
     LEFT JOIN doctor_versions p ON (a.id = p.doctor_id AND p.content_status_id = ?)
     LEFT JOIN doctor_versions d ON (a.id = d.doctor_id AND d.content_status_id = ?)
         WHERE a.active_flag = ?
      GROUP BY a.id
        HAVING (count(p.id) = 0 OR count(d.id) > 0)
      ORDER BY a.display_order", ContentStatus[:published].id, ContentStatus[:draft].id, true ])
  end
  
  def self.find_all_with_specialty(specialty_id)
    Doctor.find_all_with_specialty_and_location(specialty_id, "")
  end
  
  def self.find_all_with_specialty_and_location(specialty_id, location_id)
    specialty_id = specialty_id.to_i
    location_id = location_id.to_i
    
    sql = []
    
    sql << "SELECT a.* FROM doctors a"
    
    if location_id > 0
      sql << sanitize_sql([ "LEFT JOIN doctor_locations l ON (a.id = l.doctor_id AND l.location_id = ?)", location_id ])
    else
      sql << "LEFT JOIN doctor_locations l ON (a.id = l.doctor_id)"
    end
    
    sql << "WHERE active_flag = 1"
       
    if specialty_id > 0
      sql << sanitize_sql([ "AND a.specialty_id = ?", specialty_id ])
    end
        
    sql << "GROUP BY a.id"
    sql << "HAVING count(l.doctor_id) > 0"
    sql << "ORDER BY a.display_order"
    
    Doctor.find_by_sql(sql.join("\n"))
  end
  
  def self.find_all_with_team(team_id)
    Doctor.find_all_with_team_and_location(team_id, "")
  end
  
  def self.find_all_with_team_and_location(team_id, location_id)
    team_id = team_id.to_i
    location_id = location_id.to_i
    
    sql = []
    
    sql << "SELECT a.* FROM doctors a"
    
    sql << "WHERE active_flag = 1"
    
    if location_id > 0
      sql << sanitize_sql([ "AND (SELECT count(1) FROM doctor_locations l WHERE l.doctor_id = a.id AND l.location_id = ?) > 0", location_id ])
    end
    
    if team_id > 0
      sql << sanitize_sql([ "AND (SELECT count(1) FROM doctor_teams t WHERE t.doctor_id = a.id AND t.team_id = ?) > 0", team_id ])
    end
    
    sql << "GROUP BY a.id"
    sql << "ORDER BY a.display_order"
    
    Doctor.find_by_sql(sql.join("\n"))
  end
  
  def self.find_all_without_credentials
    Doctor.find_by_sql("
      SELECT a.*
        FROM doctors a
   LEFT JOIN doctor_credentials t ON (a.id = t.doctor_id)
    GROUP BY a.id
      HAVING COUNT(t.doctor_id) < 1
    ORDER BY a.display_order")
  end
  
  def self.find_all_without_locations
    Doctor.find_by_sql("
      SELECT a.*
        FROM doctors a
   LEFT JOIN doctor_locations t ON (a.id = t.doctor_id)
    GROUP BY a.id
      HAVING COUNT(t.doctor_id) < 1
    ORDER BY a.display_order")
  end
  
  def self.find_all_published_with_credential(credential_id)
    Doctor.find_by_sql(["
    SELECT a.*
     FROM doctors a
     JOIN doctor_credentials t ON (t.credential_id = ? AND a.id = t.doctor_id)
     JOIN doctor_versions v ON (a.id = v.doctor_id AND v.content_status_id = ?)
    WHERE a.active_flag = ?
    ORDER BY a.display_order", credential_id, ContentStatus[:published].id, true ])
  end
  
  def self.find_all_published_with_location(location_id)
    Doctor.find_by_sql(["
    SELECT a.*
     FROM doctors a
     JOIN doctor_locations t ON (t.location_id = ? AND a.id = t.doctor_id)
     JOIN doctor_versions v ON (a.id = v.doctor_id AND v.content_status_id = ?)
    WHERE a.active_flag = ?
    ORDER BY a.display_order", location_id, ContentStatus[:published].id, true ])
  end
  
  def update_attributes_with_draft(attributes)
    self.attributes = attributes
    save_with_draft
  end
  
  # mass assignment of credential ids array, doesn't save this until we've validated
  def credential_ids=(the_ids)
    self['credential_ids_set'] = the_ids.to_a.collect { |i| i.to_i }
    
    @credential_ids_set = true
  end
  
  def credential_ids
    self['credential_ids_set'] ||= self.credentials.collect { |t| t.id }
  end
  
  # mass assignment of location ids array, doesn't save this until we've validated
  def location_ids=(the_ids)
    self['location_ids_set'] = the_ids.to_a.collect { |i| i.to_i }
    
    @location_ids_set = true
  end
  
  def location_ids
    self['location_ids_set'] ||= self.locations.collect { |t| t.id }
  end  
  
  def primary_location_id
    self.location_ids[0]
  end
  
  def primary_location_id=(location)
    self.location_ids = [ location ]
  end
  
  def team_ids=(the_ids)
    self['team_ids_set'] = the_ids.to_a.collect { |i| i.to_i }
    
    @team_ids_set = true
  end
  
  def team_ids
    self['team_ids_set'] ||= self.teams.collect { |t| t.id }
  end
  
  def publications_file
    if self.publication
      self.publication.public_filename
    else
      ""
    end
  end
  
  def has_publications?
    !!self.publication
  end
  
  protected
    def validate
      if self.team_ids.length == 0
        errors.add 'team_ids', '^You must choose at least one team'
      end
      
      #if self.location_ids.length == 0
      #  errors.add 'location_ids', '^You must choose at least one practicing location'
      #end
    end
  
    def save_credentials
      if @credential_ids_set
        self.credentials.clear
      
        self.credential_ids.each do |id|
          the_new_credential = Credential.find(id)
        
          if the_new_credential
            self.credentials << the_new_credential
          end
        end
      end
    end
    
    def save_locations
      if @location_ids_set
        self.locations.clear
      
        self.location_ids.each do |id|
          the_new_location = Location.find(id)
        
          if the_new_location
            self.locations << the_new_location
          end
        end
      end
    end
    
    def save_teams
      if @team_ids_set
        self.teams.clear
      
        self.team_ids.each do |id|
          the_new_team = Team.find(id)
        
          if the_new_team
            self.teams << the_new_team
          end
        end
      end
    end
end
