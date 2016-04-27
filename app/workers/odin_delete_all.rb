class OdinDeleteAll
  @queue = :odin_queue
  def self.perform(user_id)
    puts ">>>>>>>>  OdinDeleteAll processing started"
    user = User.find(user_id)
    user.delete_all_items()
    puts "<<<<<<<<  OdinDeleteAll processing completed"
  end
end