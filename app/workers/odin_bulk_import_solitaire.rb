class OdinBulkImportSolitaire
  @queue = :odin_queue
  def self.perform(user_id, collection, input_currency, b_assign_cut_grade)
    user = User.find(user_id)
    user.bulk_import_current_batch_items(collection, input_currency, b_assign_cut_grade)
  end
end