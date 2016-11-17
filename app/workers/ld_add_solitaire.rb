class LDAddSolitaire
  @queue = :ld_queue
  def self.perform(user_id, item_properties, input_currency, b_assign_cut_grade)
    user = User.find(user_id)
    user.add_ld_item(item_properties, input_currency, b_assign_cut_grade)
  end
end