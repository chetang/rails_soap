class OdinUpdateSolitairePrice
  @queue = :odin_queue

  def self.perform(user_id, collection, input_currency)
    user = User.find(user_id)
    user.update_current_batch_item_prices(collection, input_currency)
  end
end
