class OdinBulkImportSolitaireCompleted
  @queue = :odin_queue
  def self.perform(user_id)
    Rails.logger.debug ">>>>>>>>  OdinBulkImportSolitaireCompleted processing started"
    user = User.find(user_id)
    auth = {
      "UserName" => user.odin_username,
      "Password" => user.odin_password
    }
    message = {"AuthCode" => auth}
    response = ODIN_CLIENT.call(:bulk_import_solitaires_completed) do
      message message
    end
    Rails.logger.debug "Response to BulkImportSolitairesCompleted : #{response}"
    # If no error occurs,
    Rails.logger.debug "<<<<<<<<  OdinBulkImportSolitaireCompleted processing completed"
  rescue => e
    Rails.logger.error "Rescued while adding item and processing BulkImportSolitairesCompleted with error: #{e.inspect}"
  end
end