class OdinBulkImportSolitaireCompleted
  @queue = :odin_queue

  def self.perform(auth_code)
    puts ">>>>>>>>  OdinBulkImportSolitaireCompleted processing started"
    response = ODIN_CLIENT.call(:bulk_import_process_completed) do
      message auth_code
    end
    Rails.logger.debug "Response from update_solitaire_price_process_completed : #{response}"
    puts "<<<<<<<<  OdinBulkImportSolitaireCompleted processing completed"
  end
end
