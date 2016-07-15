class LDUpdatePrices
  @queue = :ld_queue
  def self.perform(user_id, collection)
    user = User.find(user_id)
    access_token = user.get_ld_access_token("LD")
    user.update_ld_prices(access_token, collection)
  end
end