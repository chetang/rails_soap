class OdinUpdateSolitairePriceCompleted
  @queue = :odin_queue

  def self.perform(auth_code)
    puts ">>>>>>>>  OdinUpdateSolitairePriceCompleted processing started"
    response = ODIN_CLIENT.call(:update_solitaire_price_process_completed) do
      message auth_code
    end
    Rails.logger.debug "Response from update_solitaire_price_process_completed : #{response}"
    puts "<<<<<<<<  OdinUpdateSolitairePriceCompleted processing completed"
  end
end
