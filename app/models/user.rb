require 'csv'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :api_keys
  def self.authenticate(auth_params)
    user = User.find_by_email(auth_params[:UserName])
    return user if user && user.valid_password?(auth_params[:Password])
    return nil
  end

  def ld_delete_all(access_token, tried = false)
    delete_all_url = LD_ACTION_URLS[:delete_all]
    response = RestClient.post delete_all_url , {:api_call => true}, {:Authorization => "Bearer #{access_token}"}
    parsed_response = JSON.parse(response)
    if response.code == 200
      Rails.logger.debug "All Items have been successfully deleted from LD."
      # That means it is successfully done
    elsif response.code == 422
      if tried
        Rails.logger.error "Response code is #{response.code} and retried once.Logging the response which is #{response}."
      else
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.ld_delete_item(access_token, true)
      end
    else
      Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
    end
  rescue => e
    if e.http_code && e.http_code == 422
      parsed_body = JSON.parse(e.http_body)
      if parsed_body["errors"] && parsed_body["errors"]["error"] == "Please sign in."
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.ld_delete_item(access_token, true)
      else
        Rails.logger.error "Rescued ld_delete_all block and the error is #{e}"
      end
    else
      Rails.logger.error "Rescued ld_delete_all block and the error is #{e}"
    end
  end

  def ld_delete_item(access_token, certificate_id, certified_by, tried = false)
    delete_item_url = LD_ACTION_URLS[:delete_solitaire]
    response = RestClient.post delete_item_url , {:CertifiedId => certificate_id, :CertifiedBy => certified_by}, {:Authorization => "Bearer #{access_token}"}
    parsed_response = JSON.parse(response)
    if response.code == 200
      Rails.logger.debug "Item has been successfully deleted from LD."
      # That means it is successfully done
    elsif response.code == 422
      if tried
        Rails.logger.error "Response code is #{response.code} and retried once.Logging the response which is #{response}."
      else
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.ld_delete_item(access_token, certificate_id, certified_by, true)
      end
    else
      Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
    end
  rescue => e
    if e.http_code && e.http_code == 422
      parsed_body = JSON.parse(e.http_body)
      if parsed_body["errors"] && parsed_body["errors"]["error"] == "Please sign in."
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.ld_delete_item(access_token, certificate_id, certified_by, true)
      else
        Rails.logger.error "Rescued ld_delete_item block and the error is #{e}"
      end
    else
      Rails.logger.error "Rescued ld_delete_item block and the error is #{e}"
    end
  end

  def delete_item(certificate_id, certified_by)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    Rails.logger.warn "REQUEST: Odin 'delete_solitaire' is called for item with id #{certificate_id} by #{certified_by} @ #{DateTime.now}"
    delete_message = {"AuthCode" => auth, "CertifiedID" => certificate_id, "CertifiedBy" => certified_by}
    response = ODIN_CLIENT.call(:delete_solitaire) do
      message delete_message
    end
    Rails.logger.warn "RESPONSE: Odin successfully responded to 'delete_solitaire' for item with id #{certificate_id} by #{certified_by} @ #{DateTime.now} with response: #{response}"
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
    Rails.logger.warn "REQUEST: Odin 'delete_all_solitaires' is called @ #{DateTime.now}"
    delete_all_message = {"AuthCode" => auth}
    response = ODIN_CLIENT.call(:delete_all_solitaires) do
      message delete_all_message
    end
    Rails.logger.warn "RESPONSE: Odin successfully responded to 'delete_all_solitaires' @ #{DateTime.now} with response: #{response}"
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
    Rails.logger.warn "REQUEST: Odin 'delete_multiple_solitaires' is called for #{collection["SolitaireCertEntity"].length} solitaires @ #{DateTime.now}"
    bulk_delete_message = {"AuthCode" => auth, "Collection" => collection}
    response = ODIN_CLIENT.call(:delete_multiple_solitaires) do
      message bulk_delete_message
    end
    Rails.logger.warn "RESPONSE: Odin successfully responded to 'delete_multiple_solitaires' for #{collection["SolitaireCertEntity"].length} solitaires @ #{DateTime.now} with response: #{response}"
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
    # Resque.enqueue(LDUpdatePrices, self.id, priceUpdatedEntities)
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
    # Save the file in public folders
    current_time = Time.now
    sanitized_file_name = "bulk-import-diamonds-#{self.ld_username}-#{current_time.to_i.to_s}.csv"
    directory = Rails.root.join('public', "uploads/#{Rails.env}/csv/upload/LD/#{self.ld_username}", current_time.to_i.to_s)
    if !File.directory?(directory)
      FileUtils.mkdir_p directory
    end
    path = File.join(directory, sanitized_file_name)
    # Suprisingly the following block is more efficient (i.e. lesser time) than the commented simple block below
    keys = solitaireAPIEntities.collect{|se| se.keys}.flatten.uniq
    CSV.open(path, "wb") do |csv|
      csv << keys # adds the attributes name on the first line
      solitaireAPIEntities.each do |hash|
        hash_values = []
        keys.each do |k|
          hash_values << hash[k]
        end
        csv << hash_values
      end
    end
    Rails.logger.warn "INTERNAL: bulk_import_items is called @ #{DateTime.now}- created filename is #{sanitized_file_name}"
    # CSV.open(path, "wb") do |csv|
    #   csv << solitaireAPIEntities.first.keys
    #   solitaireAPIEntities.each do |hash|
    #     csv << hash.values
    #   end
    # end
    # p "TimeTaken to create the CSV is #{Time.now - current_time}"
    # Resque.enqueue(LDBulkImportSolitaire, self.id, directory, sanitized_file_name)

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
      Rails.logger.warn "REQUEST: Odin 'bulk_update_solitaire_prices' is called for #{collection.length} solitaires @ #{DateTime.now}"
      bulk_update_batch_message = {"AuthCode" => auth, "Collection" => {"SolitairePriceEntity" => collection}, "InputCurrency" => input_currency}
      # TODO : Move this call in a tube for the company
      # All ODIN related APIs should be queued in a single tube
      response = ODIN_CLIENT.call(:bulk_update_solitaire_prices) do
        message bulk_update_batch_message
      end
      Rails.logger.warn "RESPONSE: Odin successfully responded to 'bulk_update_solitaire_prices' for #{collection.length} solitaires @ #{DateTime.now} with response: #{response}"
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
    Rails.logger.error "Rescued while updating item prices in batch with error: #{e.inspect}"
  end

  def update_ld_prices(access_token, collection, tried = false)
    update_prices_url = LD_ACTION_URLS[:update_prices]
    response = RestClient.post update_prices_url , {'updated_prices[]' => collection, :api_call => true}, {:Authorization => "Bearer #{access_token}"}
    parsed_response = JSON.parse(response)
    if response.code == 200
      Rails.logger.debug "File has been successfully uploaded into LD. Validation and saving the new items is in progress."
      # That means it is successfully done
    elsif response.code == 422
      if tried
        Rails.logger.error "Response code is #{response.code} and retried once.Logging the response which is #{response}."
      else
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.update_ld_prices(access_token, collection, true)
      end
    else
      Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
    end
  rescue => e
    if e.http_code && e.http_code == 422
      parsed_body = JSON.parse(e.http_body)
      if parsed_body["errors"] && parsed_body["errors"]["error"] == "Please sign in."
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.update_ld_prices(access_token, collection, true)
      else
        Rails.logger.error "Rescued update_ld_prices block and the error is #{e}"
      end
    else
      Rails.logger.error "Rescued update_ld_prices block and the error is #{e}"
    end
  end

  def bulk_update_ld(directory, file_name, access_token, tried = false)
    directory = directory['path'] if directory.is_a?(Hash)
    path = File.join(directory, file_name)
    bulk_update_url = LD_ACTION_URLS[:bulk_update]
    Rails.logger.debug "bulk update url is #{bulk_update_url}"
    response = RestClient.post bulk_update_url , {:upload => File.open(path, 'rb'), :validate_and_upload => true, :replace_inventory => true}, {:Authorization => "Bearer #{access_token}"}
    parsed_response = JSON.parse(response)
    if response.code == 200
      Rails.logger.debug "File has been successfully uploaded into LD. Validation and saving the new items is in progress."
      # That means it is successfully done
    elsif response.code == 422
      if tried
        Rails.logger.error "Response code is #{response.code} and retried once.Logging the response which is #{response}."
      else
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.bulk_update_ld(directory, file_name, access_token, true)
      end
    else
      Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
    end
  rescue => e
    if e.http_code && e.http_code == 422
      parsed_body = JSON.parse(e.http_body)
      if parsed_body["errors"] && parsed_body["errors"]["error"] == "Please sign in."
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.bulk_update_ld(directory, file_name, access_token, true)
      else
        Rails.logger.error "Rescued bulk_update_ld block and the error is #{e}"
      end
    else
      Rails.logger.error "Rescued bulk_update_ld block and the error is #{e}"
    end
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
      Rails.logger.warn "REQUEST: Odin 'bulk_import_solitaires' is called for #{collection.length} @ #{DateTime.now}"
      bulk_import_batch_message = {"AuthCode" => auth, "Collection" => {"SolitaireAPIEntity" => collection}, "InputCurrency" => input_currency, "AssignCutGrade" => cut_grade}
      response = ODIN_CLIENT.call(:bulk_import_solitaires) do
        message bulk_import_batch_message
      end
      Rails.logger.warn "RESPONSE: Odin successfully responded to 'bulk_import_solitaires' for #{collection.length} @ #{DateTime.now} with response: #{response}"
      # Rails.logger.info "Response from bulkImportSolitaires : #{response}"
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
    Rails.logger.error "Rescued while adding item and processing BulkImportSolitaires Current batch with error: #{e.inspect}"
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
    Rails.logger.warn "REQUEST: Odin 'add_solitaire' is called @ #{DateTime.now}"
    Rails.logger.debug "AddSolitaire message is #{add_solitaire_message.inspect}"
    response = ODIN_CLIENT.call(:add_solitaire) do
      message add_solitaire_message
    end
    # If no error occurs,
    Rails.logger.warn "RESPONSE: Odin successfully responded to 'add_solitaire' @ #{DateTime.now} with response: #{response}"
    Rails.logger.debug "Response of AddSolitaire from ODIN is #{response.inspect}"
    # Rails.logger.info "Response of AddSolitaire from ODIN is #{response.inspect}"
    return response.body
  rescue => e
    Rails.logger.error "Rescued while adding item and processing AddSolitaire with error: #{e.inspect}"
  end

  def add_ld_item(access_token, item_attributes = {}, input_currency = "USD", cut_grade = false, tried = false)
    add_item_url = LD_ACTION_URLS[:add_item]
    Rails.logger.debug "add item url is #{add_item_url}"
    response = RestClient.post add_item_url , {:item_attributes => item_attributes, :api_call => true}, {:Authorization => "Bearer #{access_token}"}
    parsed_response = JSON.parse(response)
    if response.code == 200
      Rails.logger.debug "File has been successfully uploaded into LD. Validation and saving the new items is in progress."
      # That means it is successfully done
    elsif response.code == 422
      if tried
        Rails.logger.error "Response code is #{response.code} and retried once.Logging the response which is #{response}."
      else
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.add_ld_item(access_token, item_attributes, input_currency, cut_grade, true)
      end
    else
      Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
    end
  rescue => e
    if e.http_code && e.http_code == 422
      parsed_body = JSON.parse(e.http_body)
      if parsed_body["errors"] && parsed_body["errors"]["error"] == "Please sign in."
        Rails.logger.debug "Response code is 422. Seems like user is logged out. Logging back again and trying again."
        access_token = self.get_ld_access_token('LD', true)
        self.add_ld_item(access_token, item_attributes, input_currency, cut_grade, true)
      else
        Rails.logger.error "Rescued add_ld_item block and the error is #{e}"
      end
    else
      Rails.logger.error "Rescued add_ld_item block and the error is #{e}"
    end
  end

  def get_ld_access_token(company = "LD", forced = false)
    existing_api_key = self.api_keys.unexpired.active.last
    existing_access_token = existing_api_key.access_token if existing_api_key.present?
    if existing_access_token.present? && !forced
      return existing_access_token
    else
      ApiKey.mark_as_inactive(self)
      session = {:email => self.ld_username, :password => self.ld_password, :api => true}
      sessionCreateUrl = LD_API_URL + "sessions"
      response = RestClient.post sessionCreateUrl , :session => session
      parsed_response = JSON.parse(response)
      if response.code == 201
        access_token = parsed_response["api_key"]["access_token"]
        company = "LD"
        expired_at = parsed_response["api_key"]["expired_at"]
        is_active = true
        api_key = self.api_keys.build(access_token: access_token, company: company, expired_at: expired_at, is_active: is_active)
        api_key.save!
      end
      return api_key.access_token
      p "response is #{parsed_response}"
    end
  rescue => e
    p "Rescued get_ld_access_token block and the error is #{e}"
  end

end
