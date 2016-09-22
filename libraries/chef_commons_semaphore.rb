module InstanceSemaphore
  class << self

    include Chef::Mixin::ShellOut

    def load_net_http
      require 'net/http'
    end

    def load_uri
       require 'uri'
    end

    def load_aws_sdk
      require 'aws-sdk'
    end

    def start(node)
      load_aws_sdk
      retry_count = 0
      hostname = node['hostname']
      s3_bucket_name = node['semaphore']['s3_bucket_name']
      sleep_seconds = node['semaphore']['sleep_create_bucket_seconds']

      s3 = Aws::S3::Client.new(region: node['semaphore']['aws_region'])

      while true
        begin
          puts "[#{hostname}] Creating bucket #{s3_bucket_name}"
          bucket = s3.create_bucket(bucket: s3_bucket_name)
          break
        rescue Aws::S3::Errors::ServiceError => e
          puts e.message
          if retry_count > node['semaphore']['max_retry_count']
             raise 'Max number retry reached'
          else
            retry_count += 1
            puts "[#{hostname}] sleeping #{sleep_seconds} seconds until bucket has been deleted"
            sleep(sleep_seconds)
            next
          end
        end
      end
    end

    def wait_while_service_up(node)
        load_net_http
        load_uri
        retry_count = 0
        sleep_seconds = node['semaphore']['sleep_wait_service_seconds']
        url = node['semaphore']['service_url']
        uri = URI(url)
        puts "Checking if [#{url}] is up"
        while retry_count < node['semaphore']['max_retry_count']
          begin
            puts "Attempt ##{retry_count}"
            res = Net::HTTP.get_response(uri).code
            if res == '302'
              puts 'Alfresco is up!'
              break
            else
              puts "[#{res}] #{url} not available yet - sleep #{sleep_seconds} seconds"
              sleep(sleep_seconds)
              retry_count += 1
              next
            end
          rescue Timeout::Error
            puts "Timeout - Sleeping #{sleep_seconds} seconds and retrying"
            sleep(sleep_seconds)
            retry_count += 1
            next
          rescue Errno::EINVAL, Errno::ECONNRESET, EOFError,
                 Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
            puts "Error while getting http response -> exit"
            break
          end
        end
    end

    def stop(node)
      load_aws_sdk
      wait_while_service_up(node)
      sleep_seconds = node['semaphore']['sleep_delete_bucket_seconds']
      retry_count = 0
      hostname = node['hostname']
      s3 = Aws::S3::Client.new(region: node['semaphore']['aws_region'])
      puts "[#{hostname}] Deleting bucket #{node['semaphore']['s3_bucket_name']}"
      while true
        begin
          s3.delete_bucket(bucket: node['semaphore']['s3_bucket_name'])
          break
        rescue Aws::S3::Errors::NoSuchBucket
          puts "No such bucket to delete -> exit"
          break
        rescue Aws::S3::Errors::ServiceError => e
          if retry_count > node['semaphore']['max_retry_count']
             raise 'Max number retry reached'
          else
            retry_count += 1
            puts e.message
            puts "[#{hostname}] Cannot delete the bucket sleeping #{sleep_seconds} seconds to try to delete it again"
            sleep(sleep_seconds)
            next
          end
        end
      end
    end
  end
end

Chef::Recipe.send(:include, InstanceSemaphore)
