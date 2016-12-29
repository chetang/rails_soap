require 'rest_client'
class LDGetKCInventory
  @queue = :ld_queue

  def self.perform()
    source_url = KC_IN_HAND_STOCK_URL
    puts "======================= Getting / Writing inventory file ======================="
    start_time = Time.now
    puts "Getting file from '#{source_url}':"
    json_string = RestClient.get(source_url)
    puts '.'
    new_file_name = "KC_inventory.csv"
    new_file_path = "#{KC_FILE_DESTINATION_FOLDER}/#{new_file_name}"
    print "Writing to #{new_file_path}"
    count = 0
    json_objects_array = JSON.parse(json_string)
    json_object_keys = json_objects_array.first.keys
    csv_headers = []
    json_object_keys.each do |key|
      if key.downcase == "price_dollar"
        csv_headers << "Price per carats"
      elsif key.downcase == "mesurement"
        csv_headers << "Measurement"
      elsif key.downcase == "tables"
        csv_headers << "Table %"
      elsif key.downcase == "lot_number"
        csv_headers << "STOCK #"
      elsif key.downcase == "total_depth"
        csv_headers << "Depth %"
      else
        csv_headers << key
      end
    end
    CSV.open("#{new_file_path}", "w") do |csv| #open new file for write
      csv << csv_headers
      json_objects_array.each do |hash| #loop json objects
        csv << hash.values #write value to file
        print '.' if ((count+=1) % 100) == 0
      end
    end
    puts '.'
    finish_time = Time.now
    puts "Get/write completed in #{(finish_time - start_time).round} seconds."
    puts "======================= DONE ====================================================="
  end
end