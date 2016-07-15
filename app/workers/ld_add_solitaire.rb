class LDAddSolitaire
  @queue = :ld_queue
  def self.perform(user_id, item_properties, input_currency, b_assign_cut_grade)
    user = User.find(user_id)
    access_token = user.get_ld_access_token("LD")
    user.add_ld_item(access_token, item_properties, input_currency, b_assign_cut_grade)
  end
end