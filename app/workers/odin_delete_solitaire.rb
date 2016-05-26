class OdinDeleteSolitaire
  @queue = :odin_queue
  def self.perform(user_id, certificate_id, certified_by)
    puts ">>>>>>>>  OdinDeleteSolitaire processing started"
    user = User.find(user_id)
    user.delete_item(certificate_id, certified_by)
    puts "<<<<<<<<  OdinDeleteSolitaire processing completed"
  end
end