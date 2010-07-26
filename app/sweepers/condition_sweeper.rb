class ConditionSweeper < ActionController::Caching::Sweeper
  observe Condition

  def after_save(condition)
    expire_cache_for(condition)
  end  

  def after_destroy(condition)
    expire_cache_for(condition)
  end
          
  private
    def expire_cache_for(condition)
      ResponseCache.new().clear  
    end
end