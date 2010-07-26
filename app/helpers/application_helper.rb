module ApplicationHelper
  include LocalTime
  include Admin::RegionsHelper
  
  def config
    Radiant::Config
  end
  
  def default_page_title
    title + ' - ' + subtitle
  end
  
  def title
    config['admin.title'] || 'Radiant CMS'
  end
  
  def subtitle
    config['admin.subtitle'] || 'Publishing for Small Teams'
  end
  
  def logged_in?
    !current_user.nil?
  end
  
  def save_model_button(model)
    label = if model.new_record?
      "Create #{model.class.name}"
    else
      'Save Changes'
    end
    submit_tag label, :class => 'button'
  end
  
  def save_model_and_continue_editing_button(model)
    submit_tag 'Save and Continue Editing', :name => 'continue', :class => 'button'
  end
  
  # Redefine pluralize() so that it doesn't put the count at the beginning of
  # the string.
  def pluralize(count, singular, plural = nil)
    if count == 1
      singular
    elsif plural
      plural
    else
      ActiveSupport::Inflector.pluralize(singular)
    end
  end
  
  def links_for_navigation
    tabs = admin.tabs
    links = tabs.map do |tab|
      nav_link_to(tab.name, File.join(request.relative_url_root, tab.url)) if tab.shown_for?(current_user)
    end.compact
    links.join(separator)
  end
  
  def separator
    %{ <span class="separator"> | </span> }
  end
  
  def current_url?(options)
    url = case options
    when Hash
      url_for options
    else
      options.to_s
    end
    request.request_uri =~ Regexp.new('^' + Regexp.quote(clean(url)))
  end
  
  def clean(url)
    uri = URI.parse(url)
    uri.path.gsub(%r{/+}, '/').gsub(%r{/$}, '')
  end
  
  def nav_link_to(name, options)
    if current_url?(options)
      %{<strong>#{ link_to name, options }</strong>}
    else
      link_to name, options
    end
  end
  
  def admin?
    current_user and current_user.admin?
  end
  
  def developer?
    current_user and (current_user.developer? or current_user.admin?)
  end
  
  def focus(field_name)
    javascript_tag "Field.activate('#{field_name}');"
  end
  
  def updated_stamp(model)
    unless model.new_record?
      updated_by = (model.updated_by || model.created_by)
      login = updated_by ? updated_by.login : nil
      time = (model.updated_at || model.created_at)
      if login or time
        html = %{<p style="clear: left"><small>Last updated } 
        html << %{by #{login} } if login
        html << %{at #{ timestamp(time) }} if time
        html << %{</small></p>}
        html
      end
    else
      %{<p class="clear">&nbsp;</p>}
    end
  end

  def timestamp(time)
    adjust_time(time).strftime("%I:%M <small>%p</small> on %B %d, %Y")     
  end 
  
  def meta_visible(symbol)
    v = case symbol
    when :meta_more
      not meta_errors?
    when :meta, :meta_less
      meta_errors?
    end
    v ? {} : {:style => "display:none"}
  end
  
  def meta_errors?
    false
  end
  
  def toggle_javascript_for(id)
    "Element.toggle('#{id}'); Element.toggle('more-#{id}'); Element.toggle('less-#{id}');"
  end
  
  def image(name, options = {})
    image_tag(append_image_extension("admin/#{name}"), options)
  end
  
  def image_submit(name, options = {})
    image_submit_tag(append_image_extension("admin/#{name}"), options)
  end
  
  def admin
    Radiant::AdminUI.instance
  end
  
  def show_errors_for(*params)
    options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
    objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
    count   = objects.inject(0) {|sum, object| sum + object.errors.count }
    unless count.zero?
      html = {}
      [:id, :class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value unless value.blank?
        else
          html[key] = 'error'
        end
      end
      
      error_messages = objects.map do |object|
        object.errors.full_messages.map do |msg|
          content_tag(:li, msg.gsub('Slug', 'URL'))
        end
      end
      
      content_tag(:div,
      content_tag(:h2, 'Please correct the following issues to continue') <<
      content_tag(:ul, error_messages),
      html
      )
    else
      ''
    end
  end
  
  def anchor(the_string)
    the_string.downcase.gsub(" ", "_").gsub("(", "").gsub(")", "")
  end
  
  # used to output rich text editor content
  def rich_format(content)    
    content.gsub("../../../", "/").gsub("../../", "/")
  end
  
  def treatment_slots_across_types(number_of_types)
    case number_of_types
    when 1
      10
    when 2
      8
    else
      6
    end
  end
  
  # shows the correct number of treatments across the categories used.
  def output_treatments(version)
    @show_all_treatments = false
    
    output = []
    
    types = version.treatment_types.length
    slots = treatment_slots_across_types(types)
    treatments = version.treatments.length
    
    version.treatment_types.each do |type|
      types = types - 1      
      
      type_treatments = version.treatments_by_type(type)
      
      if type_treatments.length > 0
        type_output = []      
        has_more = false
        type_count = 0
        
        type_output << "<ul>"

  		  type_treatments.each do |treatment|		    
  	      if slots > types		    
  				  type_output << content_tag(:li, link_to(h(treatment.name), view_treatment_path(:slug => treatment.slug)))
  				  
  				  slots = slots - 1
  				  type_count = type_count + 1
  				else
  				  has_more = true
  				  @show_all_treatments = true
  				end
  			end       
              
  			type_output << "</ul>"
  			
  			output << "<h5>"
  			
  			if type_count == 1
          output << h(ActiveSupport::Inflector.singularize(type.name))
        else
          output << h(type.name)
        end
        
        if has_more
          output << " <a href=\"#type_#{type.slug}\" class=\"more\">More</a>"
        end
        
        output << "</h5>"
  			
  			output << type_output
      end
		end
		
		output.join("\n")
  end
  
  def output_all_treatments(version)
    output = []
    
    if @show_all_treatments 
      #output << content_tag(:h3, "All Treatments")
      
      version.treatment_types.each do |type|
        type_treatments = version.treatments_by_type(type)

        if type_treatments.length > 0
          type_output = []
            
          type_count = 0
            
          type_output << "<ul>"

    		  type_treatments.each do |treatment|	
    				type_output << content_tag(:li, link_to(h(treatment.name), view_treatment_path(:slug => treatment.slug)))
    				
    				type_count = type_count + 1
    			end       

    			type_output << "</ul>"

    			output << "<h4 id=\"type_#{type.slug}\">"

    			if type_count == 1
            output << h(ActiveSupport::Inflector.singularize(type.name))
          else
            output << h(type.name)
          end
          
          output << "</h4>"

    			output << type_output
        end
  		end
    end    
    
    output.join("\n")
  end
  
  def bio_format(text, html_options={})
    start_tag = tag('dd', html_options, true)
    text = text.to_s.dup
    text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
    text.gsub!(/\n\n+/, "</dd>\n\n#{start_tag}")  # 2+ newline  -> paragraph
    text.gsub!(/([^\n]\n)(?=[^\n])/, '\1</dd>' + start_tag) # 1 newline   -> br
    text.insert 0, start_tag
    text << "</dd>"
  end
  
  def ignore_enter_key
    update_page do |page|
      page << "if(event.keyCode == Event.KEY_RETURN) return false;"
    end
  end
  
  def breadcrumbs_for_content(version)
    result = []
    
    result << link_to('Home', admin_path)
    result << '&gt;'
    
    if version.about_page?
      result << link_to('About Us', about_pages_path)
      result << '&gt;'
      
      if version.page.slug.strip == "our_doctors_and_staff"
			  result << link_to("Our Doctors and Staff", doctors_path)
				result << '&gt;'
				result << 'Edit Introduction &amp; Meta Data'
			else
			  result << html_escape(version.page.title)
			end
  	else
      case version.page.slug
        when "conditions"
          result << link_to("Conditions", conditions_path)
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'
        when "treatments"
          result << link_to("Treatments", treatments_path)
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'
        when "testimonials"
          result << link_to("Testimonials", testimonials_path)
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'
        when "locations"
  				result << link_to("Locations", locations_path)
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'
  			when "wellness"
  			  result << link_to(version.page.slug.capitalize, content_intro_path(:slug => 'wellness'))
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'  			  
  			when "research"     
  				result << link_to(version.page.slug.capitalize, abstracts_path)
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'
  			when "ask_the_doctor"     
  				result << link_to("Ask the Doctor", questions_path)
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'
  			when "about_us"     
  				result << link_to("About Us", about_pages_path)
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'
  			when "out_of_town"     
  				result << link_to("Out of Town Hotels", hotels_path)
  				result << '&gt;'
  				result << 'Edit Introduction &amp; Meta Data'  			
        else
  			  result << html_escape(version.page.title)
  	    end
    end
  	
  	result.join(" ")
  end
  
  def auth_token    
    form_authenticity_token
  rescue
    ""
  end
  
  private  
    def append_image_extension(name)
      unless name =~ /\.(.*?)$/
        name + '.png'
      else
        name
      end
    end
end
