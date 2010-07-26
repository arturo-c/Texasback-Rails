class SearchController < ApplicationController
  layout 'radiant'
  
  before_filter :set_radiant_layout
  
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  def index
    @exact_conditions = Condition.all_published.by_exact_name(params[:q])
    @other_conditions = Condition.all_published.matching(params[:q])
    
    @exact_treatments = Treatment.all_published.by_exact_name(params[:q])
    @other_treatments = Treatment.all_published.matching(params[:q])
    
    # remove any dups
    @exact_conditions.each { |condition| @other_conditions.delete(condition) }
    @exact_treatments.each { |treatment| @other_treatments.delete(treatment) }
    
    @has_others = (@other_conditions.length > 0 or @other_treatments.length > 0)
    @has_exactas = (@exact_conditions.length > 0 or @exact_treatments.length > 0)
  end
  
  protected
    def set_radiant_layout
      @content_for_header_content = '<img class="hero" src="/_images/hero_about_us.jpg" alt="Get back to life with Texas Back Institute\'s back, neck and spine care. Make an appointment now. " width="956" height="119">'
      @content_for_body_class = "search"
      @content_for_title_tag = "Search Conditions &amp; Treatments"

      @radiant_layout = "Default Layout"
    end
end
