class LDAutomaticallyBulkImportSolitaire
  @queue = :ld_queue
  def self.perform()
    puts ">>>>>>>>  LDAutomaticallyBulkImportSolitaire processing started"
    suppliers = [
      {name: "bluestar", access_token: "e4f039d2bba868929a1d1cede28199c0"},
      {name: "venusftp", access_token: "83e8bb887dc93f2c4bde082d7fb73f2e"},
      {name: "ankitgems", access_token: "5a20a731c4427a44e7ab14bb7b70fbbe"},
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