class OdinBulkImportSolitaireCompleted
  @queue = :odin_queue

  def self.perform(auth_code)
    puts ">>>>>>>>  OdinBulkImportSolitaireCompleted processing started"
    Rails.logger.warn "REQUEST: Odin 'bulk_import_process_completed' is called @ #{DateTime.now}"
    response = ODIN_CLIENT.call(:bulk_import_process_completed) do
      message auth_code
    end
    Rails.logger.warn "RESPONSE: Odin successfully responded to 'bulk_import_process_completed' @ #{DateTime.now} with response: #{response}"
    Rails.logger.debug "Response to BulkImportSolitairesCompleted : #{response}"
    Rails.logger.debug "<<<<<<<<  OdinBulkImportSolitaireCompleted processing completed"
  rescue => e
    Rails.logger.error "Rescued while posting BulkImportSolitairesCompleted with error: #{e.inspect}"
  end
end