class FaqSweeper < ActionController::Caching::Sweeper
  observe Faq

  def after_save(record)
    expire_cache_for(record)
  end  

  def after_destroy(record)
    expire_cache_for(record)
  end
          
  private
    def expire_cache_for(record)
      expire_page(faqs_list_path)
    end
end