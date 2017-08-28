require 'csv'

# The class which allows to provide csv data to test scripts.
class CSVDataProvider
  # Method to determine the filename extension.
  #
  # @param input_file_name [String] The path of the csv file.
  def get_file_input_stream(input_file_name)
    return CSV.read(input_file_name) if input_file_name.split('.').last.eql? 'csv'
    abort('File Extension is incorrect')
  end

  # Method to get All data from csv file.
  # in Array of Hash.
  # @parame input_file_name [String] The path of the csv file.
  # @param row_num [Array<Integer>] The indexes of the row.
  #
  # @return excel_data [Array of hashes] The data needed for the script.
  def get_data(
    input_file_name:,
    row_num: nil
  )
    excel_raw_data = get_file_input_stream(input_file_name)
    header = excel_raw_data[0]
    header.map!(&:to_sym)
    row_num = (1..excel_raw_data.length - 1).to_a if row_num[0].eql? 'all'
    hashify_rows(row_num: row_num, excel_raw_data: excel_raw_data, header: header)
  end

  # Forms the Array of hashes with the data in the CSV.
  #
  # @param row_num [Array<Integer>] The indexes of the row.
  # @param excel_raw_data [Array<Hash>] The data in the CSV.
  # @param header [Array] The first header row of the CSV data.
  #
  # @return excel_data [Array<Hash>] The array of hashes of rows of CSV.
  def hashify_rows(
    row_num:,
    excel_raw_data:,
    header:
  )
    excel_data = []
    row_num.each do |i|
      row = Hash[header.zip(excel_raw_data[i])]
      row.each_key do |r|
        row[r] = nil if row[r].eql? 'nil'
        row[r] = row[r].to_s.strip if row[r]
      end
      excel_data << row
    end
    excel_data
  end
end
