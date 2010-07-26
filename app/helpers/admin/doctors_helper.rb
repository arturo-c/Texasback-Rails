module Admin::DoctorsHelper
  def add_fellowship_link
    update_page do |page|
      page[:add_fellowship_link].hide
      page[:add_fellowship_note].show
      
      page << remote_function(:url => create_fellowship_path, :with => "'name=' + prompt('New Fellowship Name:', '')")
    end        
  end  
  
  def choose_existing_document
    update_page do |page|
      page[:choose_file_block].show
      page[:upload_file_block].hide
      page[:file_upload_uploaded_data].clear
    end
  end
  
  def upload_new_document
    update_page do |page|
      page[:choose_file_block].hide
      page[:upload_file_block].show
      page[:doctor_publications_file_id].clear
    end
  end
  
  def choose_existing_image
    update_page do |page|
      page[:choose_image_block].show
      page[:upload_image_block].hide
      page[:doctor_image_uploaded_data].clear
    end
  end
  
  def upload_new_image
    update_page do |page|
      page[:choose_image_block].hide
      page[:upload_image_block].show
      page[:doctor_draft_version_attributes_doctor_image_id].clear
    end
  end
end
