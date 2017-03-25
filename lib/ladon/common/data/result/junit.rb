require 'nokogiri'

module Ladon
  # Generates JUnit XML for Jenkins.
  class JUnit
    # Generate XML according to the JUnit schema to Jenkins consumption.
    #
    # @param [String] status The status of the automation.
    # @param [Ladon::Config] config The config used to instantiate the Ladon
    #   object.
    # @param [Float] time The duration of the automation runtime in minutes.
    # @param [String] log The stringified Ladon::Logging::Logger.
    #
    # @return [String] The stringified XML.
    def self.generate(status:, config:, time:, log:)
      time *= 60 # JUnit expects in seconds but Ladon records in minutes
      binding.pry
      job_name = convert_target_path_to_job_name(config.flags.target_path)

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.testsuite(
          name: job_name,
          time: time,
          tests: 1 # Only one test per result
        ) do
          xml.testcase(
            classname: job_name,
            time: time
          ) do
            xml.send(status.downcase.to_sym, status) if status != 'SUCCESS'

            xml.send(:'system-out', log)
          end
        end
      end

      builder.to_xml
    end
  end
end

def convert_target_path_to_job_name(target_path)
  target_path.match(%r{automations/(.+)\.rb})[1].tr!('/', '.')
end
