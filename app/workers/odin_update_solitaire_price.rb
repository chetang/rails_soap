class OdinUpdateSolitairePrice
  @queue = :odin_queue

  def self.perform(user_id, collection_key, input_currency)
    puts ">>>>>>>>  OdinUpdateSolitairePrice processing started"
    user = User.find(user_id)
    user.update_current_batch_item_prices(collection_key, input_currency)
    puts "<<<<<<<<  OdinUpdateSolitairePrice processing completed"
  end
end
