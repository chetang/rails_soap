require 'rest_client'
class LDGetAndModifyHKInventory
  @queue = :ld_queue

  def self.perform()
    source_url = HK_SOURCE_URL
    puts "======================= Getting / Modifying inventory file ======================="
    start_time = Time.now
    puts "Getting file from '#{source_url}':"
    csv_string = RestClient.get(source_url)
    puts '.'
    new_file_name = "HK_Liquids.csv"
    new_file_path = "#{HK_FILE_DESTINATION_FOLDER}/#{new_file_name}"
    print "Writing to #{new_file_path}"
    count = 0
    CSV.open(new_file_path, 'w') do |csv_writer|
      first_row = true
      CSV.parse(csv_string) do |row|
        if first_row
          revised_headers = []
          row.each do |header|
            if header.strip.downcase == 'RTE'.downcase
              # Rename RTE ==> "Price per carat"
              header = "Price per carat"
            elsif header.strip.downcase == 'CRTWT'.downcase
              # Rename CRTWT ==> "Cts"
              header = "Cts"
            end
            revised_headers << header
          end
          row = revised_headers
          first_row = false
        end
        csv_writer << row
        print '.' if ((count+=1) % 100) == 0
      end
    end
    puts '.'
    finish_time = Time.now
    puts "Get/modify/write completed in #{(finish_time - start_time).round} seconds."
    puts "======================= DONE ====================================================="
  end
end