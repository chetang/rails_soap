class LDDeleteSolitaire
  @queue = :ld_queue
  def self.perform(user_id, certificate_id, certified_by)
    user = User.find(user_id)
    user.ld_delete_item(certificate_id, certified_by)
  end
end