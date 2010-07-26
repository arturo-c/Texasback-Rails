class HomePage
  def self.published
    HomePageVersion.find_by_content_status_id(ContentStatus[:published].id)
  end
  
  def self.draft
    HomePageVersion.find_by_content_status_id(ContentStatus[:draft].id)
  end
  
  def self.has_draft?
    draft = HomePageVersion.find_by_content_status_id(ContentStatus[:draft].id)
    
    return !!draft
  end
  
  def self.has_published?
    published = HomePageVersion.find_by_content_status_id(ContentStatus[:published].id)
    
    return !!published
  end

  def self.create_draft
    unless HomePage.has_draft?
      if HomePage.has_published?
        @draft_version = HomePage.published.clone
      else
        @draft_version = HomePageVersion.new
      end

      @draft_version.content_status_id = ContentStatus[:draft].id
    end

    @draft_version
  end
  
  # Reverts the draft version fields given back to the current published version
  def self.revert_fields(*field_names)
    draft_version = HomePage.draft
    published_version = HomePage.published
    
    field_names.each do |field|      
      draft_version[field.to_s] = published_version[field.to_s]
    end
    
    draft_version.save
  end
  
  # Publishes a new version with content from existing published version, except new data for the given fields
  def self.publish_fields(*field_names)
    draft_version = HomePage.draft
    published_version = HomePage.published
    
    new_published_version = published_version.clone
    
    field_names.each do |field|
      new_published_version[field.to_s] = draft_version[field.to_s]
    end
    
    published_version.update_attribute(:content_status_id, ContentStatus[:archive].id)
    published_version.update_attribute(:archive_date, Time.now)
    
    new_published_version.save
  end
end