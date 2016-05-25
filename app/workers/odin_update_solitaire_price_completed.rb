class OdinUpdateSolitairePriceCompleted
  @queue = :odin_queue

  def self.perform(user_id)
    Rails.logger.debug ">>>>>>>>  OdinUpdateSolitairePriceCompleted processing started"
    user = User.find(user_id)
    auth = {
      "UserName" => user.odin_username,
      "Password" => user.odin_password
    }
    message = {"AuthCode" => auth}
    response = ODIN_CLIENT.call(:update_prices_completed) do
      message message
    end
    Rails.logger.debug "Response to UpdatePricesCompleted : #{response}"
    # If no error occurs,
    Rails.logger.debug "<<<<<<<<  OdinUpdateSolitairePriceCompleted processing completed"
  rescue => e
    Rails.logger.error "Rescued while adding item and processing UpdatePricesCompleted with error: #{e.inspect}"
  end
end
