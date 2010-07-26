class TermGroup < ActiveRecord::Base
  validates_presence_of :name, :characters
  has_many :terms
  
  named_scope :all, :order => 'display_order'
  
  def self.[](value)
    self.find_by_name(value.to_s)
  end
  
  def self.find_by_term_name(name)
    first_letter = name.to_s.downcase.split(//)[0]
    
    # if the first letter isn't a letter, then just use the first group
    if (first_letter =~ /^[A-Za-z]+/) == 0
      TermGroup.find(:first, :conditions => [ 'characters like ? ', "%#{first_letter}%" ])
    else
      TermGroup.find(:first)
    end
  end
  
  def has_published_terms?
    self.published_terms.length > 0
  end
  
  def published_terms
    @published_terms ||= Term.all_published.by_group(self.id)
  end
end
