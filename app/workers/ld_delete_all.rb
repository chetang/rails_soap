class LDDeleteAll
  @queue = :ld_queue
  def self.perform(user_id)
    user = User.find(user_id)
    access_token = user.get_ld_access_token("LD")
    user.ld_delete_all(access_token)
  end
end