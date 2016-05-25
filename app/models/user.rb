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
    delete_message = {"AuthCode" => auth, "CertifiedID" => certificate_id, "CertifiedBy" => certified_by}
    response = ODIN_CLIENT.call(:delete_solitaire) do
      message delete_message
    end
    Rails.logger.info "Response from delete_solitaire ODIN is : #{response}"
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
    Resque.enqueue(LDUpdatePrices, self.id, priceUpdatedEntities)
    while processed_count < items_count
      if current_processed_count > items_count
        current_processed_count = items_count
      end
      current_collection = priceUpdatedEntities[processed_count...current_processed_count]
      p "resque enqueuing OdinUpdateSolitairePrice for current_collection: #{current_collection}"
      Resque.enqueue(OdinUpdateSolitairePrice, self.id, current_collection, input_currency)
      processed_count = current_processed_count
      current_processed_count += BATCH_PROCESSING_COUNT
    end
    # Resque.enqueue(OdinUpdateSolitairePriceCompleted, self.id)
    # Call ODIN API
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing UpdatedPrices with error: #{e.inspect}"
  end

  def update_current_batch_item_prices(collection, input_currency)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    bulk_update_batch_message = {"AuthCode" => auth, "Collection" => {"PriceUpdatedEntity" => collection}, "InputCurrency" => input_currency}
    response = ODIN_CLIENT.call(:update_solitaire_price) do
      message bulk_update_batch_message
    end
    Rails.logger.debug "Response to updateSolitairePrice : #{response}"
    puts "Response to updateSolitairePrice : #{response}"
    # Call ODIN API
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing UpdateSolitairePrice with error: #{e.inspect}"
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
      p "enqueuing OdinBulkImportSolitaire for current_collection: #{current_collection}"
      Resque.enqueue(OdinBulkImportSolitaire, self.id, current_collection, input_currency, cut_grade)
      processed_count = current_processed_count
      current_processed_count += BATCH_PROCESSING_COUNT
    end
    # Resque.enqueue(OdinBulkImportSolitaireCompleted, self.id)
    # Call ODIN API
    # Convert the collection into a CSV and call the bulk upload API of LD
    # The API Should be called using background processing
    # If no error occurs,
    return true
  rescue => e
    Rails.logger.error "Rescued while adding item and processing BulkImportSolitaires with error: #{e.inspect}"
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
        Rails.logger.error "Rescued bulk_update_ld block and the error is #{e}"
      end
    else
      Rails.logger.error "Rescued bulk_update_ld block and the error is #{e}"
    end
  end

  def bulk_update_ld(directory, file_name, access_token, tried = false)
    directory = directory['path'] if directory.is_a?(Hash)
    path = File.join(directory, file_name)
    bulk_update_url = LD_ACTION_URLS[:bulk_update]
    Rails.logger.debug "bulk update url is #{bulk_update_url}"
    response = RestClient.post bulk_update_url , {:upload => {file: File.new(path, 'rb')}, :api_call => true}, {:Authorization => "Bearer #{access_token}"}
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

  def bulk_import_current_batch_items(collection, input_currency, cut_grade)
    auth = {
      "UserName" => self.odin_username,
      "Password" => self.odin_password
    }
    collection.each do |entity|
      entity.delete_if{|k, v| v.nil?}
    end
    bulk_import_batch_message = {"AuthCode" => auth, "Collection" => {"SolitaireAPIEntity" => collection}, "InputCurrency" => input_currency, "AssignCutGrade" => cut_grade}
    response = ODIN_CLIENT.call(:bulk_import_solitaires) do
      message bulk_import_batch_message
    end
    Rails.logger.info "Response from bulkImportSolitaires Current batch : #{response}"
    puts "Response from bulkImportSolitaires Current batch : #{response}"
    # If no error occurs,
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
    p "AddSolitaire message is #{add_solitaire_message.inspect}"
    response = ODIN_CLIENT.call(:add_solitaire) do
      message add_solitaire_message
    end
    # If no error occurs,
    p "Response of AddSolitaire from ODIN is #{response.inspect}"
    Rails.logger.info "Response of AddSolitaire from ODIN is #{response.inspect}"
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
        Rails.logger.error "Rescued bulk_update_ld block and the error is #{e}"
      end
    else
      Rails.logger.error "Rescued bulk_update_ld block and the error is #{e}"
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
