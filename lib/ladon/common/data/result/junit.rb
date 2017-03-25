require 'nokogiri'

module Ladon
  # Generates JUnit XML for Jenkins.
  class JUnit
    def self.generate(status:, config:, time:, log:)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.testsuite(
          name: config.class_name,
          time: time,
          tests: 1 # Only one test per result
        ) do
          xml.testcase(
            classname: config.class_name,
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
