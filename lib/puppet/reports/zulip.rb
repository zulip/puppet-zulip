require 'puppet'
require 'yaml'
require 'net/https'
require 'json'



Puppet::Reports.register_report(:zulip) do

  API_VERSION = '1'

  configfile = File.join([File.dirname(Puppet.settings[:config]), "zulip.yaml"])
  raise(Puppet::ParseError, "Zulip report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  ZULIP_STATUSES = Array(config[:zulip_statuses] || 'failed')

  ZULIP_TYPE = config[:type]
  ZULIP_BOTEMAIL = config[:botemail]
  ZULIP_KEY = config[:key]
  ZULIP_TO = config[:to]
  ZULIP_SUBJECT = config[:subject]
  ZULIP_SITE = config[:zulip_site]
  DISABLED_FILE = File.join([File.dirname(Puppet.settings[:config]), 'zulip_disabled'])
  
  CONFIG = config

  desc <<-DESC
  Send report information to Zulip.
  DESC

  def process
    # Disabled check here to ensure it is checked for every report
    disabled = File.exists?(DISABLED_FILE)
    if (ZULIP_STATUSES.include?(self.status) || ZULIP_STATUSES.include?('all')) && !disabled

      output = []
      self.logs.each do |log|
        output << log
      end

      if self.environment.nil?
        self.environment == 'production'
      end

      message = "Puppet #{self.environment} run for #{self.host} #{self.status} at #{Time.now.asctime}."
      if CONFIG[:github_user] && CONFIG[:github_password]
        gist_id = gist(self.host,output)
        message << " Created a Gist showing the output at #{gist_id}"
      end

      if CONFIG[:logs]
        self.logs.each do |log|
          if log.to_s !~ /Loading facts/
            message << log.to_s + "\n"
          end
        end
      end

      if CONFIG[:parsed_reports_dir]
        report_server = Socket.gethostname
        report_path = last_report
        message << " Summary at #{report_server}:#{report_path}"
      end

      if CONFIG[:report_url] and CONFIG[:report_url].is_a?(String)
        map = {
          'c' => self.respond_to?(:configuration_version) ? self.configuration_version : nil,
          'e' => self.respond_to?(:environment)           ? self.environment : nil,
          'h' => self.respond_to?(:host)                  ? self.host : nil,
          'k' => self.respond_to?(:kind)                  ? self.kind : nil,
          's' => self.respond_to?(:status)                ? self.status : nil,
          't' => self.respond_to?(:time)                  ? self.time : nil,
          'v' => self.respond_to?(:puppet_version)        ? self.puppet_version : nil,
        }
        message << " Report URL: "
        message << CONFIG[:report_url].gsub(/%([#{map.keys}])/) {|s| map[$1].to_s }
      end

      zulip_api = (ZULIP_SITE.sub %r{^https?:(//|\\\\)(www\.)?}i, '').concat('/api')
      Puppet.debug "Sending status for #{self.host} to #{ZULIP_TO}"
      https = Net::HTTP.new(zulip_api, '443')
      https.use_ssl = true

      request = Net::HTTP::Post.new("/v#{API_VERSION}/messages")
      request.add_field('User-Agent', 'ZulipPuppet/0.0.2')
      request.basic_auth("#{ZULIP_BOTEMAIL}", "#{ZULIP_KEY}")

      if ZULIP_TYPE == 'stream'
        request.set_form_data({'type' => 'stream', 'to' => "#{ZULIP_TO}", 'subject' => "#{ZULIP_SUBJECT}", 'content' => message})
      elsif ZULIP_TYPE == 'private'
        request.set_form_data({'type' => 'private', 'to' => "#{ZULIP_TO}",'content' => message})
      end

      resp = https.request(request)
    end
  end
  def gist(host,output)
    max_attempts = 2
    begin
      timeout(8) do
        https = Net::HTTP.new('api.github.com', 443)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.start {
          req = Net::HTTP::Post.new('/gists')
          req.add_field("User-Agent", "#{CONFIG[:github_user]}")
          req.basic_auth "#{CONFIG[:github_user]}", "#{CONFIG[:github_password]}"
          req.content_type = 'application/json'
          req.body = JSON.dump({
            "files" => { "#{host}-#{Time.now.to_i.to_s}" => { "content" => output.join("\n") } },
            "description" => "Puppet #{environment} run failed on #{host} @ #{Time.now.asctime}",
            "public" => false
          })
          response = https.request(req)
          gist_id = JSON.parse(response.body)["html_url"]
        }
      end
    rescue Timeout::Error
      Puppet.notice "Timed out while attempting to create a GitHub Gist, retrying ..."
      max_attempts -= 1
      if max_attempts > 0
        retry
      else
        Puppet.err "Timed out while attempting to create a GitHub Gist."
      end
    end
  end

  def last_report
    destfile = File.join([CONFIG[:parsed_reports_dir], self.host + '-' + rand.to_s])

    File.open(destfile, 'w+', 0644) do |f|

      f.puts("\n\n\n#### Report for #{self.name},\n")
      f.puts("     puppet run at #{self.time}:\n\n")

      self.resource_statuses.each do |resource,properties|
        if properties.failed
          f.puts "\n#{resource} failed:\n    #{properties.file} +#{properties.line}\n"
        end
      end

      f.puts "\n\n#### Logs captured on the node:\n\n"

      self.logs.each do |log|
        f.puts log
      end

      f.puts "\n\n#### Summary:\n\n"
      f.puts self.summary
    end

    destfile

  end
end
