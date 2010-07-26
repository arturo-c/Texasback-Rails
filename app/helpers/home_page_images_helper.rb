module HomePageImagesHelper
  def home_page_image_name(slot)
    case slot
      when "news" then "News"
      when "wellness" then "Wellness"
      when "research" then "Research"
      when "testimonials" then "Testimonials"
      when "conditions" then "Conditions &amp; Treatments"
      when "events" then "Events &amp; Outreach"
      when "minvasive" then "Minimally Invasive"
    end
  end
end