module Admin::EventImagesHelper
  def after_remove_event_image(image)
    update_page do |page|
      page.visual_effect 'Fade', "event_image_#{image.id}", :afterFinish => "function() { $('event_image_#{image.id}').remove(); fixFloats(); }"
    end
  end
  
  def on_remove_event_image(image)
    update_page do |page|
      page["event_image_#{image.id}"].down("div.controls").update(image_tag("/images/ajax-loader.gif", :alt => 'loading'))
    end
  end
end
