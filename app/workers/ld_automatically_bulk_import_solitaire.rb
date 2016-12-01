class LDAutomaticallyBulkImportSolitaire
  @queue = :ld_queue
  def self.perform()
    Rails.logger.warn  ">>>>>>>>  LDAutomaticallyBulkImportSolitaire processing started"
    suppliers = [
      {name: "bluestar", access_token: "8ccf8b94cba2986088a2cc5147487ec4"},
      {name: "venusftp", access_token: "2c7d667820f3c8b7a3369fc0bde67195"},
      {name: "ankitgems", access_token: "d8cecd66998578d89ae1c614ad83d821"},
      {name: "kiran", access_token: "a63210ead6d96dc15efda1ef252c9457"},
      {name: "harikrishna", access_token: "f46700ffb203bcd322e3cb9003ee2efb"},
      {name: "kgirdharlal", access_token: "a38f122abda8861bf9bdb28342824601"},
      {name: "jewelex", access_token: "3030aad2c090dd87b7791afc135ac3a3"},
      {name: "rosyblue", access_token: "a0e57fece79ee65c4f12c4c503753bd6"},
      {name: "shreeramkrishna", access_token: "9eb7a75603f3556d20709a5608842450"},
      {name: "kantilalchhotalal", access_token: "95bd43d9ebe6bfd247a491a16d07d4ea"},
      {name: "shairugems", access_token: "6e080274c2213873def71877ce537a97"},
    ]
    suppliers.each do |supplier|
      begin
        directory = Rails.root.join('public', "ftp_upload/#{supplier[:name]}")
        path = Dir.glob(File.join(directory, '*.*')).max { |a,b| File.ctime(a) <=> File.ctime(b) }
        unless path
          Rails.logger.warn "<<<<<<<<<<<< Skipping BulkImportSolitaires for #{supplier[:name]} as no file was found"
          next
        end
        bulk_update_url = LD_ACTION_URLS[:bulk_update]
        Rails.logger.debug "bulk update url is #{bulk_update_url}"
        response = RestClient.post bulk_update_url , {:upload => File.open(path, 'rb'), :validate_and_upload => true, :replace_inventory => true}, {:Authorization => "Bearer #{supplier[:access_token]}", 'Content-Type' => 'application/csv'}
        parsed_response = JSON.parse(response)
        if response.code == 200
          File.delete(path)
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
    Rails.logger.warn  "<<<<<<<<  LDAutomaticallyBulkImportSolitaire processing completed for #{supplier[:name]}"
  rescue => e
    p "Rescued LDAutomaticallyBulkImportSolitaire perform block and the error is #{e}"
  end
end