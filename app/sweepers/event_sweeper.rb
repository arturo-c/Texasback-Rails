class EventSweeper < ActionController::Caching::Sweeper
  observe Event

  def after_save(record)
    expire_cache_for(record)
  end  

  def after_destroy(record)
    expire_cache_for(record)
  end
          
  private
    def expire_cache_for(record)
      directory = ActionController::Base.page_cache_directory + "/about_us/events"
      
      Dir["#{directory}/*"].each do |f|
        FileUtils.rm_rf f
      end
      
      expire_page(events_list_path)
    end
end