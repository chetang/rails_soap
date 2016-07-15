class OdinUpdateSolitairePriceCompleted
  @queue = :odin_queue

  def self.perform(auth_code)
    Rails.logger.debug ">>>>>>>>  OdinUpdateSolitairePriceCompleted processing started"
    response = ODIN_CLIENT.call(:update_solitaire_price_process_completed) do
      message auth_code
    end
    Rails.logger.debug "Response to UpdatePricesCompleted : #{response}"
    puts "<<<<<<<<  OdinUpdateSolitairePriceCompleted processing completed"
    # If no error occurs,
    Rails.logger.debug "<<<<<<<<  OdinUpdateSolitairePriceCompleted processing completed"
  rescue => e
    Rails.logger.error "Rescued while posting UpdatePricesCompleted with error: #{e.inspect}"
  end
end
