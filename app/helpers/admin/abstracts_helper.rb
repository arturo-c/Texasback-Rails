module Admin::AbstractsHelper
  def add_topic_link
    update_page do |page|
      page[:add_topic_link_row].hide
      page[:add_topic_field_row].show().down('input').activate
      page << "$('new_topic_name').value = '';"
    end
  end
  
  def add_topic_button
    remote_function({
        :url => research_topics_path, 
        :with => "'research_topic[name]=' + $('new_topic_name').getValue().strip() + '&research_topic[slug]=' + $('new_topic_name').getValue().toSlug() + '&research_topic[draft_version_attributes][page_title]=' + $('new_topic_name').getValue().strip()",
        :before => "$(this).up('span.controls').hide().next('span.loading').show()" })
  end
  
  def cancel_add_topic
    update_page do |page|
      page[:add_topic_link_row].show
      page[:add_topic_field_row].hide
    end
  end
end