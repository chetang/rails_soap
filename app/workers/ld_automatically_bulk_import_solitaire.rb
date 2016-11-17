class LDAutomaticallyBulkImportSolitaire
  @queue = :ld_queue
  def self.perform()
    Rails.logger.warn  ">>>>>>>>  LDAutomaticallyBulkImportSolitaire processing started"
    suppliers = [
      {name: "bluestar", access_token: "579af7e10132f46daffaf8b90a05eb23"},
      {name: "venusftp", access_token: "7da7009a595af36b2641414918c024e7"},
      {name: "ankitgems", access_token: "162e66209b8ac2c7f74bcba0291b1f7b"},
      {name: "kiran", access_token: "42572a1da99f7cb49c7fbcc1eb2c18cd"},
      {name: "harikrishna", access_token: "ddf7d52543be7ea8f8c303661bec31b1"},
      {name: "kgirdharlal", access_token: "8fa11267cd1248968815b120f7f00e23"},
      {name: "jewelex", access_token: "873097a79519ebde8a3620416dbdaf6f"},
      {name: "rosyblue", access_token: "06250b814d4925de443faf29f77bbcc9"},
      {name: "shreeramkrishna", access_token: "4a0abea2bc1fb8fb420bfc49de28be56"},
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