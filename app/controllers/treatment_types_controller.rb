class TreatmentTypesController < ApplicationController
  layout 'radiant'

   before_filter :set_radiant_layout

   session :off

   skip_before_filter :verify_authenticity_token

   no_login_required

   caches_page :show

   def show
     @type = TreatmentType.find_by_slug(params[:slug]) 
     @content_for_title_tag = @type.name
   end

   protected
     # allows rails to use this existing radiant layout by name
     def set_radiant_layout
       @content_for_header_content = header_content_for_page('injections')
       @content_for_body_class = body_class_for_page('injections')       

       @radiant_layout = "Default Layout"
     end
end
