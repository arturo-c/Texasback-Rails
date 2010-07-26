module Admin::TreatmentsHelper
  def type_options
    options_for_select = []
    
    options_for_select << %(<option value="">All</option>)
    
    @types.collect do |type|
      selected_attribute = ' selected="selected"' if type.id.to_s == params[:type]
      
      if type.top? 
        options_for_select << %(<option value="#{type.id}"#{selected_attribute}>#{html_escape(type.name)}</option>)
      else
        options_for_select << %(<option value="#{type.id}"#{selected_attribute}>&nbsp;&nbsp;#{html_escape(type.name)}</option>)
      end
    end
    
    options_for_select.join("\n")
  end
end
