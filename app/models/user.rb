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

  def update_item_price(certificate_id, certified_by, updated_price)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    update_price_message = {"AuthCode" => auth, "CertifiedID" => certificate_id, "CertifiedBy" => certified_by, "UpdatedPrice" => updated_price}
    response = ODIN_CLIENT.call(:udpate_solitaire_price) do
      message update_price_message
    end
    # TODO : Add the above API call in background process
    # Call the LD API
    return true
  rescue => e
    Rails.logger.error "Rescued while updating item price and processing UpdateSolitairePrice with error: #{e.inspect}"
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
    # TODO : Add the above API call in background process
    # Call the LD API
    return true
  rescue => e
    Rails.logger.error "Rescued while deleting items and processing DeleteAllSolitaires with error: #{e.inspect}"
  end

  def update_prices(collection, input_currency = "USD")
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    priceUpdatedEntities = collection[:PriceUpdatedEntity]
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
      p "resque enqueuing OdinBulkImportSolitaire for current_collection: #{current_collection}"
      Resque.enqueue(OdinUpdateSolitairePrice, self.id, current_collection, input_currency)
      processed_count = current_processed_count
      current_processed_count += BATCH_PROCESSING_COUNT
    end

    # Call ODIN API
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing BulkImportSolitaires with error: #{e.inspect}"
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
      p "resque enqueuing OdinBulkImportSolitaire for current_collection: #{current_collection}"
      Resque.enqueue(OdinBulkImportSolitaire, self.id, current_collection, input_currency, cut_grade)
      processed_count = current_processed_count
      current_processed_count += BATCH_PROCESSING_COUNT
    end

    # Call ODIN API
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing BulkImportSolitaires with error: #{e.inspect}"
  end

  def update_current_batch_item_prices(collection, input_currency)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }

    bulk_update_batch_message = {"AuthCode" => auth, "Collection" => {"PriceUpdatedEntity" => collection}, "InputCurrency" => input_currency}
    # TODO : Move this call in a tube for the company
    # All ODIN related APIs should be queued in a single tube
    response = ODIN_CLIENT.call(:update_solitaire_price) do
      message bulk_update_batch_message
    end
    puts "Response to updateSolitairePrice : #{response}"
    # Call ODIN API
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing UpdateSolitairePrice with error: #{e.inspect}"
  end

  def bulk_import_current_batch_items(collection, input_currency, cut_grade)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }

    bulk_import_batch_message = {"AuthCode" => auth, "Collection" => {"SolitaireAPIEntity" => collection}, "InputCurrency" => input_currency, "AssignCutGrade" => cut_grade}
    # TODO : Move this call in a tube for the company
    # All ODIN related APIs should be queued in a single tube
    response = ODIN_CLIENT.call(:bulk_import_solitaires) do
      message bulk_import_batch_message
    end
    puts "Response to bulkImportSolitaires : #{response}"
    # Call ODIN API
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing BulkImportSolitaires with error: #{e.inspect}"
  end

  def add_odin_item(item_attributes = {}, input_currency = "USD", cut_grade = false)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    add_solitaire_message = {"AuthCode" => auth, "Entity" => item_attributes, "InputCurrency" => input_currency, "AssignCutGrade" => cut_grade}
    # TODO : Move this call in a tube for the company
    # Call ODIN API
    # The API Should be called using backgound processing
    # All ODIN related APIs should be queued in a single tube
    p "AddSolitaire message is #{add_solitaire_message.inspect}"
    response = ODIN_CLIENT.call(:add_solitaire) do
      message add_solitaire_message
    end
    # TODO: Call LD Restful API
    # If no error occurs,
    p "Response of AddSolitaire from ODIN is #{response.inspect}"
    return response.body
  rescue => e
    Rails.logger.error "Rescued while adding item and processing AddSolitaire with error: #{e.inspect}"
  end

end
