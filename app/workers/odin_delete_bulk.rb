class OdinDeleteBulk
  @queue = :odin_queue
  def self.perform(user_id, collection)
    puts ">>>>>>>>  OdinDeleteBulk processing started"
    user = User.find(user_id)
    user.delete_solitaires(collection)
    puts "<<<<<<<<  OdinDeleteBulk processing completed"
  end
end