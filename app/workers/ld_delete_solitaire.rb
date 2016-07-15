class LDDeleteSolitaire
  @queue = :ld_queue
  def self.perform(user_id, certificate_id, certified_by)
    user = User.find(user_id)
    access_token = user.get_ld_access_token("LD")
    user.ld_delete_item(access_token, certificate_id, certified_by)
  end
end