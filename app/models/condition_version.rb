class ConditionVersion < ActiveRecord::Base
  validates_presence_of :condition_id, :content_status_id, :full_description, :page_title
  validates_presence_of :area_id, :message => "must be selected"
  
  validates_length_of :treatment_intro, :maximum => 300
  validates_length_of :symptoms, :maximum => 320
  validates_length_of :description, :maximum => 360
  
  belongs_to :condition
  belongs_to :content_status
  belongs_to :area
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :created_by, :class_name => 'User'
  has_and_belongs_to_many :treatments, :join_table => 'condition_treatments', :uniq => true
  has_many :condition_version_images, :dependent => :delete_all
  
  after_save :save_treatments
  after_save :save_images
  
  def published?
    self.content_status_id == ContentStatus[:published].id
  end  
  
  def archive?
    self.content_status_id == ContentStatus[:archive].id
  end
  
  def draft?
    self.content_status_id == ContentStatus[:draft].id
  end
  
  def status
    self.content_status
  end
  
  def modified?
    self.updated_at > self.created_at
  end
  
  def publish
    if draft? && self.condition
      existing_published_version = self.condition.published
      
      if existing_published_version
        existing_published_version.update_attribute(:content_status_id, ContentStatus[:archive].id)
        existing_published_version.update_attribute(:archive_date, Time.now)
      end
      
      self.content_status_id = ContentStatus[:published].id
      
      self.save
    else
      false
    end
  end
  
  def show_treatment_intro
    !self.treatment_intro.blank?
  end
  
  def show_treatment_intro=(flag)
    unless flag == '1'
      self.treatment_intro = ""
    end
  end
  
  # mass assignment of treatment ids array, doesn't save this until we've validated
  def treatment_ids=(the_ids)
    self['treatment_ids_set'] = the_ids.to_a.collect { |i| i.to_i }
  end
  
  def treatment_ids
    self['treatment_ids_set'] ||= self.treatments.collect { |t| t.id }
  end
  
  # returns an array of the treatment types (always uses parent) used within the treatment_ids for this condition_version
  def treatment_types
    types = []
    
    self.treatment_ids.each do |id|
      the_treatment = Treatment.find(id)
      
      if the_treatment
        if the_treatment.has_published?
          types << the_treatment.type.id
        end
      end
    end
    
    TreatmentType.find(types.uniq, :order => 'display_order')
  end
  
  def treatments_by_type(type)
    type_id = type.is_a?(TreatmentType) ? type.id : type
    
    self.treatments.by_type_or_parent(type_id)
  end
  
  def image_ids
    @image_ids ||= self.condition_version_images.collect(&:condition_image_id)
  end
  
  def images
    @images ||= ConditionImage.find(image_ids)
  end
  
  def images=(image_ids)
    @image_ids = image_ids    
    @images = nil
    
    @modified_images = true    
  end
  
  def has_images?
    self.image_ids.length > 0
  end
  
  protected
    def validate
      # if this page is draft or published, there can be no other versions of that status      
      if self.draft?
        other_versions = find_other_by_condition_id_and_status(self.condition_id, ContentStatus[:draft].id)
        
        errors.add :content_status_id, 'is already taken for this condition' if other_versions.length > 0
      end
      
      if self.published?
        other_versions = find_other_by_condition_id_and_status(self.condition_id, ContentStatus[:published].id)
        
        errors.add :content_status_id, 'is already taken for this condition' if other_versions.length > 0
      end
    end
    
    def find_other_by_condition_id_and_status(condition_id, content_status_id)
      if self.new_record?
        ConditionVersion.find_all_by_condition_id_and_content_status_id(condition_id, content_status_id)
      else
        ConditionVersion.find(:all, :conditions => [ "condition_id = ? AND content_status_id = ? AND id <> ?", condition_id, content_status_id, self.id ])
      end
    end
    
    def save_treatments
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
    
    def save_images
      if @modified_images
        self.condition_version_images.clear
        
        @image_ids.each_with_index do |image_id, index|
          i = ConditionVersionImage.new(:condition_version_id => self.id, :condition_image_id => image_id, :display_order => index)
          i.save
        end
      end
    end
end
