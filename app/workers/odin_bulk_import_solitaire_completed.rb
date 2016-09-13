class OdinBulkImportSolitaireCompleted
  @queue = :odin_queue

  def self.perform(auth_code)
    puts ">>>>>>>>  OdinBulkImportSolitaireCompleted processing started"
    response = ODIN_CLIENT.call(:bulk_import_process_completed) do
      message auth_code
    end
    Rails.logger.debug "Response to BulkImportSolitairesCompleted : #{response}"
    Rails.logger.debug "<<<<<<<<  OdinBulkImportSolitaireCompleted processing completed"
  rescue => e
    Rails.logger.error "Rescued while posting BulkImportSolitairesCompleted with error: #{e.inspect}"
  end
end