class TermSweeper < ActionController::Caching::Sweeper
  observe Term

  def after_save(record)
    expire_cache_for(record)
  end  

  def after_destroy(record)
    expire_cache_for(record)
  end
          
  private
    def expire_cache_for(record)
      expire_page(terms_list_path)
      expire_page(glossary_js_path)
    end
end