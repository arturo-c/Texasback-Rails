class ResearchTopicSweeper < ActionController::Caching::Sweeper
  observe ResearchTopic

  def after_save(record)
    expire_cache_for(record)
  end  

  def after_destroy(record)
    expire_cache_for(record)
  end
          
  private
    def expire_cache_for(record)
      cache = ResponseCache.new      
      cache.clear
    end
end