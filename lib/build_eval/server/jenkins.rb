module BuildEval
  module Server

    class Jenkins

      def initialize(args = {})
        @base_uri = args[:uri]
        @username = args[:username]
        @password = args[:password]
      end

      def build_result(name)
        response = BuildEval::Http.get("#{@base_uri}/api/xml", username: @username, password: @password)
        color = get_build_color(response.body, name)
        build_status = determine_status(color.to_s)
        raise "Unexpected build response: #{response.message}" unless build_status
        BuildEval::Result::BuildResult.create(build_name: name, status_name: build_status)
      end


      def to_s
        "Jenkins CI #{@base_uri}"
      end

      private
        def get_build_color(body, name)
          Nokogiri::XML(body).xpath("//hudson/job[name/text()='#{name}']/color/text()[1]")
        end

        def determine_status(color)
          case color
          when "red"
            return "Failure"
          when "blue"
            return "Success"
          when "aborted"
            return "Unknown"
          when "yellow"
            return "Warning"
          else
            return nil
          end
        end
    end
  end
end
