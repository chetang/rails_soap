class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def self.authenticate(auth_params)
    user = User.find_by_email(auth_params[:UserName])
    return user if user && user.valid_password?(auth_params[:Password])
    return nil
  end

  def delete_item(certificate_id, certified_by)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    delete_message = {"AuthCode" => auth, "CertifiedID" => certificate_id, "CertifiedBy" => certified_by}
    response = ODIN_CLIENT.call(:delete_solitaire) do
      message delete_message
    end
    Rails.logger.debug "Response from delete_solitaire ODIN is : #{response}"
    # TODO : Add the above API call in background process
    # Call the LD API
    return true
  rescue => e
    Rails.logger.error "Rescued while deleting item and processing DeleteSolitaire with error: #{e.inspect}"
  end

  def delete_all_items
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    delete_all_message = {"AuthCode" => auth}
    response = ODIN_CLIENT.call(:delete_all_solitaires) do
      message delete_all_message
    end
    Rails.logger.info "Response from delete_all_solitaires ODIN is : #{response}"
    # TODO : Add the above API call in background process
    # Call the LD API
    return true
  rescue => e
    Rails.logger.error "Rescued while deleting items and processing DeleteAllSolitaires with error: #{e.inspect}"
  end

  def delete_solitaires(collection)
    raise "Collection can't be nil. Please provide a list of objects with 'CertifiedBy' and 'CertifiedID'" if collection.blank?
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    bulk_delete_message = {"AuthCode" => auth, "Collection" => collection}
    response = ODIN_CLIENT.call(:delete_multiple_solitaires) do
      message bulk_delete_message
    end
    Rails.logger.info "Response from delete_multiple_solitaires ODIN is : #{response}"
    # Call the LD API
    return true
  rescue => e
    Rails.logger.error "Rescued while deleting items and processing DeleteMultipleSolitaires with error: #{e.inspect}"
  end

  def update_prices(collection, input_currency = "USD")
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    priceUpdatedEntities = collection[:SolitairePriceEntity]
    items_count = priceUpdatedEntities.length
    # TODO : Call the Odin API in batch of BATCH_PROCESSING_COUNT
    # Also the calls must be made using background processing
    processed_count = 0
    current_processed_count = BATCH_PROCESSING_COUNT
    while processed_count < items_count
      if current_processed_count > items_count
        current_processed_count = items_count
      end
      current_collection = priceUpdatedEntities[processed_count...current_processed_count]
      json_formatted_current_collection = JSON.dump(current_collection)
      key = Time.now.to_i.to_s
      bulk_import_current_batch_cs = nil
      CollectionStorage.transaction do
        bulk_import_current_batch_cs = CollectionStorage.new({user_id: self.id, key: key, collection: json_formatted_current_collection, company: 'kiran'})
        bulk_import_current_batch_cs.save!
      end
      Rails.logger.debug "Enqueuing OdinUpdateSolitairePrice for current_collection of length: #{current_collection.length}"
      Resque.enqueue(OdinUpdateSolitairePrice, self.id, bulk_import_current_batch_cs.id, input_currency)
      processed_count = current_processed_count
      current_processed_count += BATCH_PROCESSING_COUNT
    end
    # Call Odin UpdateSolitairePriceProcessCompleted API
    bulk_update_completed_message = {"AuthCode" => auth}
    Resque.enqueue(OdinUpdateSolitairePriceCompleted, bulk_update_completed_message)
    # All ODIN related APIs should be queued in a single tube
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing whole UpdateSolitairePrice with error: #{e.inspect}"
  end

  def bulk_import_items(collection, input_currency = "USD", cut_grade = false)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    solitaireAPIEntities = collection[:SolitaireAPIEntity]
    items_count = solitaireAPIEntities.length
    # TODO : Call the Odin API in batch of BATCH_PROCESSING_COUNT
    # Also the calls must be made using background processing
    processed_count = 0
    current_processed_count = BATCH_PROCESSING_COUNT
    while processed_count < items_count
      if current_processed_count > items_count
        current_processed_count = items_count
      end
      current_collection = solitaireAPIEntities[processed_count...current_processed_count]
      json_formatted_current_collection = JSON.dump(current_collection)
      key = Time.now.to_i.to_s
      bulk_import_current_batch_cs = nil
      CollectionStorage.transaction do
        bulk_import_current_batch_cs = CollectionStorage.new({user_id: self.id, key: key, collection: json_formatted_current_collection, company: 'kiran'})
        bulk_import_current_batch_cs.save!
      end
      Rails.logger.debug "Enqueuing OdinBulkImportSolitaire for current_collection of length: #{current_collection.length}"
      Resque.enqueue(OdinBulkImportSolitaire, self.id, bulk_import_current_batch_cs.id, input_currency, cut_grade)
      processed_count = current_processed_count
      current_processed_count += BATCH_PROCESSING_COUNT
    end
    # Call Odin BulkImportProcessCompleted API
    bulk_update_completed_message = {"AuthCode" => auth}
    Resque.enqueue(OdinBulkImportSolitaireCompleted, bulk_update_completed_message)
    # Call ODIN API
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing whole BulkImportSolitaires with error: #{e.inspect}"
  end

  def update_current_batch_item_prices(collection_key, input_currency)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    batch_cs = CollectionStorage.find(collection_key)
    if batch_cs.present?
      collection_string = batch_cs.collection
      collection = JSON.parse(collection_string)
      bulk_update_batch_message = {"AuthCode" => auth, "Collection" => {"SolitairePriceEntity" => collection}, "InputCurrency" => input_currency}
      # TODO : Move this call in a tube for the company
      # All ODIN related APIs should be queued in a single tube
      response = ODIN_CLIENT.call(:bulk_update_solitaire_prices) do
        message bulk_update_batch_message
      end
      Rails.logger.debug "Response from bulk_update_solitaire_prices : #{response}"
      # Call ODIN API
      # Convert the collection into a CSV and call the bulk upload API of LD
      # The API Should be called using background processing
      # If no error occurs,
    else
      Rails.logger.error "NEED ATTENTION - update_current_batch_item_prices CollectionStorage could not be found with id: #{collection_key}"
    end
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing UpdateSolitairePrice with error: #{e.inspect}"
  end

  def bulk_import_current_batch_items(collection_key, input_currency, cut_grade)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }

    # TODO : Move this call in a tube for the company
    # All ODIN related APIs should be queued in a single tube
    batch_cs = CollectionStorage.find(collection_key)
    if batch_cs.present?
      collection_string = batch_cs.collection
      collection = JSON.parse(collection_string)
      collection.each do |entity|
        entity.delete_if{|k, v| v.nil?}
      end
      bulk_import_batch_message = {"AuthCode" => auth, "Collection" => {"SolitaireAPIEntity" => collection}, "InputCurrency" => input_currency, "AssignCutGrade" => cut_grade}
      response = ODIN_CLIENT.call(:bulk_import_solitaires) do
        message bulk_import_batch_message
      end
      Rails.logger.info "Response from bulkImportSolitaires : #{response}"
      puts "Response from bulkImportSolitaires : #{response}"
      # Call ODIN API
      # Convert the collection into a CSV and call the bulk upload API of LD
      # The API Should be called using background processing
      # If no error occurs,
    else
      Rails.logger.error "NEED ATTENTION - bulk_import_current_batch_items CollectionStorage could not be found with id: #{collection_key}"
    end
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing BulkImportSolitaires with error: #{e.inspect}"
  end

  def add_odin_item(item_attributes = {}, input_currency = "USD", cut_grade = false)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    item_attributes.delete_if{|key,value| value.nil? }
    add_solitaire_message = {"AuthCode" => auth, "Entity" => item_attributes, "InputCurrency" => input_currency, "AssignCutGrade" => cut_grade}
    # TODO : Move this call in a tube for the company
    # Call ODIN API
    # The API Should be called using backgound processing
    # All ODIN related APIs should be queued in a single tube
    Rails.logger.debug "AddSolitaire message is #{add_solitaire_message.inspect}"
    response = ODIN_CLIENT.call(:add_solitaire) do
      message add_solitaire_message
    end
    # TODO: Call LD Restful API
    # If no error occurs,
    Rails.logger.debug "Response of AddSolitaire from ODIN is #{response.inspect}"
    Rails.logger.info "Response of AddSolitaire from ODIN is #{response.inspect}"
    return response.body
  rescue => e
    Rails.logger.error "Rescued while adding item and processing AddSolitaire with error: #{e.inspect}"
  end

end
