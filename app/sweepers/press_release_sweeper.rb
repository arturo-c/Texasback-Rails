class PressReleaseSweeper < ActionController::Caching::Sweeper
  observe PressRelease

  def after_save(record)
    expire_cache_for(record)
  end  

  def after_destroy(record)
    expire_cache_for(record)
  end
          
  private
    def expire_cache_for(record)
      ResponseCache.new().clear
    end
end