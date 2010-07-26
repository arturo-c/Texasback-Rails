class JavascriptsController < ApplicationController
  session :off
  
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  caches_page :glossary
  
  def glossary
    @terms = Term.all_published
    
    respond_to do |format|
      format.js # glossary.js.erb
    end
  end
end