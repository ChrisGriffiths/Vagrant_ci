module Vagrant_ci
    module Jenkins
            require 'net/http'
            def self.heartbeat
                Thread.new do |t|
                    while true
                        begin
                            puts "HEARTBEAT"
                            STDOUT.flush
                            build_status
                            sleep 60
                        rescue Exception => e
                            puts "Pinger Errored"
                            p e
                            sleep 60
                        end
                    end
                end
            end

            def self.build_status
                build_number = ENV['BUILD_NUMBER']
                job_name = ENV['JOB_NAME']
                return p "Jenkins Build Status Not Configured" if job_name.nil? or build_number.nil?

                uri = URI.parse("https://api.access:f391db39b71a58d2119edeb6d0ceac36@mns-jenkins.cloudapp.net/job/#{job_name}/#{build_number}/api/json?tree=building")

                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                request = Net::HTTP::Get.new(uri.request_uri)
                request.basic_auth(uri.user, uri.password)
                response = http.request(request)
                Process.kill("HUP", Process.ppid) if response.body.include? 'false'
            end
        end
end