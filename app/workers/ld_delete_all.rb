class LDDeleteAll
  @queue = :ld_queue
  def self.perform(user_id)
    user = User.find(user_id)
    user.ld_delete_all()
  end
end