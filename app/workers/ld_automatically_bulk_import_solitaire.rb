class LDAutomaticallyBulkImportSolitaire
  @queue = :ld_queue
  def self.perform()
    Rails.logger.warn  ">>>>>>>>  LDAutomaticallyBulkImportSolitaire processing started"
    suppliers = [
      {name: "bluestar", access_token: "6130c42177aca8f2138aa0314fe276e2"},
      {name: "venusftp", access_token: "555259423f3dad59a3306c91f0b7a2d6"},
      {name: "ankitgems", access_token: "6e890130d9ec9d39caaf9cba9c06f248"},
      {name: "kiran", access_token: "3a6fc8dd8d8cd2ac3ca20b38e2ce97ef"},
      {name: "harekrishna", access_token: "e1cf55f78584da3d8182c41e9a45388c"},
      {name: "kgirdharlal", access_token: "54224f603c74bbdde3662b0564a7e2a1"},
      {name: "jewelex", access_token: "a8142447f2736676d17947ad4738d40c"},
      {name: "rosyblue", access_token: "c00e016ee6a91cc6a0719d776f2cf06b"},
      {name: "shreeramkrishna", access_token: "b98efe04a689091606fffa9d5b0ac4fb"},
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