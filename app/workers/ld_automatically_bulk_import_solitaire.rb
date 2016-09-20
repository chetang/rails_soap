class LDAutomaticallyBulkImportSolitaire
  @queue = :ld_queue
  def self.perform()
    puts ">>>>>>>>  LDAutomaticallyBulkImportSolitaire processing started"
    suppliers = [
      {name: "bluestar", access_token: "7bd3598446275bd428b7f3f883b641b8"},
      {name: "venusftp", access_token: ""},
      # {name: "ankitgems", access_token: ""},
    ]
    suppliers.each do |supplier|
      begin
        directory = Rails.root.join('public', "ftp_upload/#{supplier[:name]}")
        path = Dir.glob(File.join(directory, '*.*')).max { |a,b| File.ctime(a) <=> File.ctime(b) }
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
        Rails.logger.error "Rescued bulk_update_ld block and the error is #{e}"
      end
    end
    puts "<<<<<<<<  LDAutomaticallyBulkImportSolitaire processing completed"
  rescue => e
    p "Rescued LDAutomaticallyBulkImportSolitaire perform block and the error is #{e}"
  end
end