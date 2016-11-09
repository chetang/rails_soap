class LDAutomaticallyBulkImportSolitaire
  @queue = :ld_queue
  def self.perform()
    Rails.logger.warn  ">>>>>>>>  LDAutomaticallyBulkImportSolitaire processing started"
    suppliers = [
      {name: "bluestar", access_token: "2f91de447a3001afea73c83e6f710ee4"},
      {name: "venusftp", access_token: "409f1fb72ab801895d213fff4cab6ce5"},
      {name: "ankitgems", access_token: "fc4306e804c0968703bcadbd3d512c17"},
      {name: "kiran", access_token: "1acd09c3673172b5259d5f874d2a1f2f"},
      # {name: "harekrishna", access_token: "6156cc685b63b67b50ab34519918d201"},
      # {name: "kgirdharlal", access_token: "32f9b4195d4cb3a6cf95f81075a59bfb"},
    ]

    suppliers.each do |supplier|
      begin
        directory = Rails.root.join('public', "ftp_upload/#{supplier[:name]}")
        path = Dir.glob(File.join(directory, '*.*')).max { |a,b| File.ctime(a) <=> File.ctime(b) }
        next unless path
        bulk_update_url = LD_ACTION_URLS[:bulk_update]
        Rails.logger.debug "bulk update url is #{bulk_update_url}"
        response = RestClient.post bulk_update_url , {:upload => File.open(path, 'rb'), :validate_and_upload => true, :replace_inventory => true}, {:Authorization => "Bearer #{supplier[:access_token]}", 'Content-Type' => 'application/csv'}
        parsed_response = JSON.parse(response)
        if response.code == 200
          Rails.logger.debug "File has been successfully uploaded into LD. Validation and saving the new items is in progress."
          # That means it is successfully done
        elsif response.code == 422
          Rails.logger.error "Response code is #{response.code}.Logging the response #{response}."
        else
          Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
        end
      rescue => e
        Rails.logger.error "Rescued LDAutomaticallyBulkImportSolitaire block and the error is #{e}"
      end
    end
    Rails.logger.warn  "<<<<<<<<  LDAutomaticallyBulkImportSolitaire processing completed"
  rescue => e
    p "Rescued LDAutomaticallyBulkImportSolitaire perform block and the error is #{e}"
  end
end