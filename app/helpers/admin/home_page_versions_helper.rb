module Admin::HomePageVersionsHelper
  def edit_homepage_path_for(from_path)
    case from_path.strip.downcase
      when "edit_meta" 
        edit_home_page_meta_path
      when "edit_news"        
        edit_home_page_news_path
      when "edit_wellness"
        edit_home_page_wellness_path
      when "edit_research"
        edit_home_page_research_path
      when "edit_review"
        edit_home_page_review_path
      when "edit_events"
        edit_home_page_events_path
      when "edit_conditions"
        edit_home_page_conditions_path
      else 
        edit_home_page_path
    end
  end
end
