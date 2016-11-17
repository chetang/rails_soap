class LDUpdatePrices
  @queue = :ld_queue
  def self.perform(user_id, collection)
    user = User.find(user_id)
    user.update_ld_prices(collection)
  end
end