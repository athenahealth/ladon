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
      job_name = convert_path_to_job_name(config.path)
      fragments = job_name.rpartition('.')
      suite_name = fragments.first
      case_name = fragments.last

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.testsuite(
          name: suite_name,
          time: time,
          tests: 1 # Only one test per result
        ) do
          xml.testcase(
            classname: suite_name,
            name: case_name,
            time: time
          ) do
            xml.send(status.downcase.to_sym, status) if status != 'SUCCESS'

            xml.send(:'system-out', log)
          end
        end
      end

      builder.to_xml
    end

    # Removes automations prefix and rb extension. Converts '/' into '.' for
    # Jenkins hierachy mapping.
    #
    # @param [String] path The path to the automation.
    #
    # @return [String] The converted path.
    private_class_method def self.convert_path_to_job_name(path)
      path.match(%r{automations/(.+)\.rb})[1].tr('/', '.')
    end
  end
end
