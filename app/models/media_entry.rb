class MediaEntry < ActiveRecord::Base
  include ERB::Util
  
  validates_presence_of :entry_date, :source, :summary
  
  belongs_to :media_logo
  
  named_scope :all, :order => 'entry_date DESC'
  named_scope :active, :conditions => { :active_flag => true }, :order => 'entry_date DESC'
  named_scope :inactive, :conditions => { :active_flag => false }, :order => 'entry_date DESC'
  
  def active?
    self.active_flag
  end
  
  def name
    self.topic.blank? ? self.source : self.summary
  end
  
  def has_logo?
    !!self.media_logo
  end
  
  def logo
    self.media_logo.public_filename
  end
  
  def source_formatted
    self.italicize_source ? "<em>#{h(self.source)}</em>" : h(self.source)
  end
  
  def article_formatted
    self.quote_article ? "&#8220;#{h(self.article)}&#8221;" : h(self.article)
  end
  
  def new_media_logo
    nil
  end
  
  def new_media_logo=(value)
    unless value.to_s.blank?
      logo = MediaLogo.new(:uploaded_data => value)
      
      if logo.save
        self.media_logo_id = logo.id
      end
    end
  end
end
