class QuestionSweeper < ActionController::Caching::Sweeper
  observe Question, QuestionTopic

  def after_save(record)
    expire_cache_for(record)
  end  

  def after_destroy(record)
    expire_cache_for(record)
  end
          
  private
    def expire_cache_for(record)
      directory = ActionController::Base.page_cache_directory + "/ask_the_doctor"
      
      Dir["#{directory}/*"].each do |f|
        FileUtils.rm_rf f
      end
      
      expire_page(questions_list_path)      
    end
end