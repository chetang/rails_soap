class OdinDeleteAll
  @queue = :odin_queue
  def self.perform(user_id)
    user = User.find(user_id)
    user.delete_all_items()
  end
end