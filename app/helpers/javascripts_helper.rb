module JavascriptsHelper
  def terms_json_list_for(terms)
    result = {}
    
    terms.each do |term|
      unless term.name.match(/'|"|\(|\)/)
        result[term.id] = { :id => term.id, :name => term.name, :definition => term.published.definition }
      end
    end
    
    result.to_json
  end
end