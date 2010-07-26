module Admin::PressReleasesHelper
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
      page[:press_release_file_upload_id].clear
    end
  end
end
