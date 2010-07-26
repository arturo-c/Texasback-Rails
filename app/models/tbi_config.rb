class TbiConfig < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def self.[](the_name)
    if @@tbi_config[the_name]
      @@tbi_config[the_name]
    else
      @@tbi_config[the_name] = self.find_by_name(the_name.to_s.downcase).value
    end
  rescue
    return ""
  end
  
  def self.update_config(name, value)
    logger.info "Updating Config Value [#{name}]"
    
    @config = TbiConfig.find_by_name(name.to_s.downcase)
    
    @config.update_attribute(:value, value)
    
    @@tbi_config = {}
  end
  
  @@tbi_config = {}
end