module Admin::ConditionImagesHelper
  def after_remove_image(image)
    update_page do |page|
      page.visual_effect 'Fade', "condition_image_#{image.id}", :afterFinish => "function() { $('condition_image_#{image.id}').remove(); fixFloats(); }"
    end
  end
  
  def on_remove_image(image)
    update_page do |page|
      page["condition_image_#{image.id}"].down("div.controls").update(image_tag("/images/ajax-loader.gif", :alt => 'loading'))
    end
  end
end
