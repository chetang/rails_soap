class OdinUpdateSolitairePrice
  @queue = :odin_queue
  def self.perform(user_id, certificate_id, certified_by, updated_price)
    user = User.find(user_id)
    user.update_item_price(certificate_id, certified_by, updated_price)
  end
end
