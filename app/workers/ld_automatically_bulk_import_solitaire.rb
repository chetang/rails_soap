require "csv-diff"

class LDAutomaticallyBulkImportSolitaire
  @queue = :ld_queue

  def self.process_to_be_deleted_row_keys(to_be_deleted_keys)
    return [] if to_be_deleted_keys.blank?
    result = []
    to_be_deleted_keys.each do |key|
      lab, certificate_id = *key.split("~") # The order depends on the ordering of key_fields in suppliers array definition
      result << {CertifiedBy: lab, CertifiedId: certificate_id}
    end
    return result
  end

  def self.generate_add_update_file(directory, supplier, original_file_path, to_be_added_uploaded_rows)
    if !File.directory?(directory)
      FileUtils.mkdir_p directory
    end
    supplier_only_add_update_rows_file = "#{supplier[:name]}-only-add-delete.csv"
    path = File.join(directory, supplier_only_add_update_rows_file)
    index = 0
    CSV.open(path, "w") do |csv|
      File.open(original_file_path,'rb').each do |line|
        begin
          CSV.parse(line) do |row|
            if to_be_added_uploaded_rows.include?(index)
              csv << row
            end
          end
        rescue  CSV::MalformedCSVError => er
          Rails.logger.warn er.message
          Rails.logger.warn "Writing invalid file: Captured CSV::MalformedCSVError"
          # and continue
        rescue => e
          log_rescue(e)
        end
        index += 1
      end
    end
    return path
  end

  def self.bulk_delete(supplier, to_be_deleted_keys)
    bulk_delete_url = LD_ACTION_URLS[:bulk_delete]
    Rails.logger.debug "bulk update url is #{bulk_delete_url}"
    RestClient.post bulk_delete_url , {'to_be_deleted_items[]' => process_to_be_deleted_row_keys(to_be_deleted_keys), :api_call => true}, {:Authorization => "Bearer #{supplier[:access_token]}"}
  end

  def self.bulk_import(supplier, file, is_sync = false)
    bulk_update_url = LD_ACTION_URLS[:bulk_update]
    Rails.logger.debug "bulk update url is #{bulk_update_url}"
    RestClient.post bulk_update_url , {:upload => File.open(file, 'rb'), :validate_and_upload => true, :replace_inventory => is_sync}, {:Authorization => "Bearer #{supplier[:access_token]}", 'Content-Type' => 'application/csv'}
  end


  def self.perform()
    Rails.logger.warn  ">>>>>>>>  LDAutomaticallyBulkImportSolitaire processing started"
    # suppliers = [
    #   {name: "bluestar", access_token: "8ccf8b94cba2986088a2cc5147487ec4"},
    #   {name: "venusftp", access_token: "2c7d667820f3c8b7a3369fc0bde67195"},
    #   {name: "ankitgems", access_token: "d8cecd66998578d89ae1c614ad83d821"},
    #   {name: "kiran", access_token: "a63210ead6d96dc15efda1ef252c9457"},
    #   {name: "harikrishna", access_token: "f46700ffb203bcd322e3cb9003ee2efb"},
    #   {name: "kgirdharlal", access_token: "a38f122abda8861bf9bdb28342824601"},
    #   {name: "jewelex", access_token: "3030aad2c090dd87b7791afc135ac3a3"},
    #   {name: "rosyblue", access_token: "a0e57fece79ee65c4f12c4c503753bd6"},
    #   {name: "shreeramkrishna", access_token: "9eb7a75603f3556d20709a5608842450"},
    #   {name: "kantilalchhotalal", access_token: "95bd43d9ebe6bfd247a491a16d07d4ea"},
    #   {name: "shairugems", access_token: "6e080274c2213873def71877ce537a97"},
    # ]
    suppliers = [
      {name: "bluestar",          access_token: "8ccf8b94cba2986088a2cc5147487ec4", key_fields: ["LAB", "Certificate #" ]},
      {name: "venusftp",          access_token: "2c7d667820f3c8b7a3369fc0bde67195", key_fields: ["Lab", "Certificate #" ]},
      {name: "ankitgems",         access_token: "d8cecd66998578d89ae1c614ad83d821", key_fields: ["Lab", "Certificate #" ]},
      {name: "kiran",             access_token: "a63210ead6d96dc15efda1ef252c9457", key_fields: ["Lab", "Certificate #" ]},
      {name: "harikrishna",       access_token: "f46700ffb203bcd322e3cb9003ee2efb", key_fields: ["LAB", "CERT_NO"       ]},
      {name: "kgirdharlal",       access_token: "a38f122abda8861bf9bdb28342824601", key_fields: ["Lab", "Certificate #" ]},
      {name: "jewelex",           access_token: "3030aad2c090dd87b7791afc135ac3a3", key_fields: ["Lab", "CertificateID" ]},
      {name: "rosyblue",          access_token: "a0e57fece79ee65c4f12c4c503753bd6", key_fields: ["Lab", "CertificateNo" ]},
      {name: "shreeramkrishna",   access_token: "9eb7a75603f3556d20709a5608842450", key_fields: ["LAB", "Certificate #" ]},
      {name: "kantilalchhotalal", access_token: "95bd43d9ebe6bfd247a491a16d07d4ea", key_fields: ["LAB", "Certificate #" ]},
      {name: "shairugems",        access_token: "6e080274c2213873def71877ce537a97", key_fields: ["Lab", "CertiNo"       ]},
    ]

    suppliers.each do |supplier|
      begin
        # Get the latest uploaded copy
        new_file_directory = Rails.root.join('public', "ftp_upload/#{supplier[:name]}")
        new_file_path = Dir.glob(File.join(new_file_directory, '*.*')).max { |a,b| File.ctime(a) <=> File.ctime(b) }
        unless new_file_path
          # puts "Skipping for supplier #{supplier[:name]} as no (new) inventory file found"
          next
        end
        # So, we have the latest file.
        # Get the old copy
        old_file_directory = Rails.root.join('public', "ftp_old_copy/#{supplier[:name]}")
        old_file_path = Dir.glob(File.join(old_file_directory, '*.*')).max { |a,b| File.ctime(a) <=> File.ctime(b) }
        only_new_updated_rows_file = nil
        if old_file_path
          # Compare the two CSVs to find out the differences
          start_time = Time.now
          diff = CSVDiff.new(old_file_path, new_file_path, key_fields:supplier[:key_fields])
          time_taken = Time.now - start_time
          # puts "Time taken to find differences is #{time_taken}"
          # puts diff.summary.inspect
          to_be_added_uploaded_rows = [0] # As we always want to include Headers in the new CSV
          to_be_deleted_keys = []
          if diff.adds.length > 0
            diff.adds.values.each{|row| to_be_added_uploaded_rows << row[:row]}
          end
          if diff.updates.length > 0
            diff.updates.values.each{|row| to_be_added_uploaded_rows << row[:row]}
          end
          to_be_deleted_keys = diff.deletes.keys
          if to_be_deleted_keys.length > 0
            # puts "#{to_be_deleted_keys.length} diamonds found that needs to be deleted. "
            begin
              response = bulk_delete(supplier, to_be_deleted_keys)
              # puts "Response for the bulk_delete is #{response} and code is #{response.code}"
              if response.code == 200
                Rails.logger.debug "Items have been successfully deleted"
                # puts "Items have been successfully deleted"
              else
                Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
                # puts "Unhandled response. Response code is #{response.code} and response is #{response}."
              end
            rescue => e
              Rails.logger.error "Bulk Delete raised on exception and the error is #{e}"
              # puts "Bulk Delete raised on exception and the error is #{e}"
            end
          end
          # Create a CSV from to_be_added_uploaded_rows
          if to_be_added_uploaded_rows.length > 1 # By default, it's length is 1 as it has 0 as it's first row_number
            only_new_updated_rows_file = generate_add_update_file(new_file_directory, supplier, new_file_path, to_be_added_uploaded_rows)
            # Call BulkImport without sync and the above created CSV as uploaded file
            response = bulk_import(supplier, only_new_updated_rows_file, false)
            # puts "Response for the bulk_udpate w/o sync is #{response} and code is #{response.code}"
            if response.code == 200
              # Removing file after every successful upload, as uploads are always done whenever there is a file in the folder.
              # Files are only transferred to this folder if a new file has been uploaded which is taken care of by the check_ftp_upload script run via Cron Job every minute
              Rails.logger.debug "File with only selected(new/updated) rows has been successfully uploaded into LD without syncing enitre inventory. Validation and saving the new items is in progress."
              # puts "File with only selected(new/updated) rows has been successfully uploaded into LD without syncing enitre inventory. Validation and saving the new items is in progress."
            else
              Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
              # puts "Unhandled response. Response code is #{response.code} and response is #{response}."
            end
            FileUtils.rm(only_new_updated_rows_file)
          end
        else
          # Call BulkImport with sync as there is no old CSV to compare from
          response = bulk_import(supplier, new_file_path, true)
          if response.code == 200
            Rails.logger.debug "Enitre file has been successfully uploaded into LD. Validation and saving the new items is in progress."
            # puts "Enitre file has been successfully uploaded into LD. Validation and saving the new items is in progress."
          else
            Rails.logger.error "Unhandled response. Response code is #{response.code} and response is #{response}."
            # puts "Unhandled response. Response code is #{response.code} and response is #{response}."
          end
        end
        # Moving the recently uploaded file into old_copy
        copying_path = Rails.root.join('public', "ftp_old_copy/#{supplier[:name]}#{new_file_path.remove(new_file_directory.to_s)}")
        # puts "Moving newly uploaded CSV to old_copy"
        if !File.directory?(old_file_directory)
          FileUtils.mkdir_p old_file_directory
        end
        FileUtils.mv(new_file_path, copying_path)
      rescue => e
        if only_new_updated_rows_file
          FileUtils.rm(only_new_updated_rows_file)
        end
        Rails.logger.error "Rescued supplier compare and update inventory block for #{supplier[:name]} and the error is #{e}"
        # puts "Rescued supplier compare and update inventory block for #{supplier[:name]} and the error is #{e}"
      end
    end
  rescue => e
    p "Rescued LDAutomaticallyBulkImportSolitaire perform block and the error is #{e}"
  end
end