module Admin::EventsHelper
  def hours
    (1...13).to_a.collect { |i| i.to_s }
  end
  
  def minutes
    [ '00', '15', '30', '45' ]
  end
  
  def ampms
    [ 'AM', 'PM' ]
  end
  
  def add_topic_link
    update_page do |page|
      page[:add_topic_link_row].hide
      page[:add_topic_field_row].show().down('input').activate
      page << "$('new_topic_name').value = '';"
    end
  end
  
  def add_topic_button
    remote_function({
        :url => event_topics_path, 
        :with => "'event_topic[name]=' + $('new_topic_name').getValue().strip() + '&event_topic[slug]=' + $('new_topic_name').getValue().toSlug() + '&event_topic[draft_version_attributes][page_title]=' + $('new_topic_name').getValue().strip()",
        :before => "$(this).up('span.controls').hide().next('span.loading').show()" })
  end
  
  def cancel_add_topic
    update_page do |page|
      page[:add_topic_link_row].show
      page[:add_topic_field_row].hide
    end
  end
end
