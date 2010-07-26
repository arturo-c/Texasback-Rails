class HomeSweeper < ActionController::Caching::Sweeper
  observe HomePageVersion

  def after_save(record)
    expire_cache_for(record)
  end  

  def after_destroy(record)
    expire_cache_for(record)
  end
          
  private
    def expire_cache_for(record)
      expire_page(homepage_path)
    end
end