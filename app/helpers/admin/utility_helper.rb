module Admin::UtilityHelper
  def crossfade(from, to)
    update_page do |page|
      page << "$('#{from.to_s}').crossFadeWith('#{to.to_s}');"
    end   
  end
end
