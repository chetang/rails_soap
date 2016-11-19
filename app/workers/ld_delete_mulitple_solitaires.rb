class LDDeleteMultipleSolitaires
  @queue = :ld_queue
  def self.perform(user_id, collection)
    user = User.find(user_id)
    user.ld_delete_multiple_solitaires(collection)
  end
end