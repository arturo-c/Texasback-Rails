class LocationSweeper < ActionController::Caching::Sweeper
  observe Location

  def after_save(record)
    expire_cache_for(record)
  end  

  def after_destroy(record)
    expire_cache_for(record)
  end
          
  private
    def expire_cache_for(record)
      expire_page(view_locations_path)
    end
end