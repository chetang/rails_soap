class LDBulkImportSolitaire
  @queue = :ld_queue
  def self.perform(user_id, directory, sanitized_file_name)
    puts ">>>>>>>>  LDBulkImportSolitaire processing started"
    user = User.find(user_id)
    # Log the user into LD app
    access_token = user.get_ld_access_token("LD")
    # Send the file as multipart to LD bulk API
    user.bulk_update_ld(directory, sanitized_file_name, access_token)
    puts "<<<<<<<<  LDBulkImportSolitaire processing completed"
  rescue => e
    p "Rescued LDBulkImportSolitaire perform block and the error is #{e}"
  end
end