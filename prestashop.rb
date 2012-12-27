require 'rest_client'
require 'yaml'
require 'json'
require 'nokogiri'
require 'curl'

module PrestaShop
	CONFIGS_PATH = "/var/www/auto/configs.yml"
	CONFIGS      = YAML.load(File.open(CONFIGS_PATH))
	
	def self.list_configs
		CONFIGS.keys
	end
	
	def self.connect shop_name
		@config = CONFIGS[shop_name]
		
		RestClient.add_before_execution_proc do |req, params|
		  if @cookies
			req['Cookie'] = @cookies.map{|k,v| "#{k}=#{v}"}.join("; ")
		  end
		  #puts params
		end
		
		self.authenticate
	end
	
	def self.goto where
		url = if @urls and @urls[where] then @urls[where] else where end
		response = RestClient.get(url)	
		@body = Nokogiri::HTML(response)
		
		@urls = {}
		@body.css('a').each do |a|
			if tab=a['href'][/\?controller=(\w+)&/,1]
				@urls[tab] = @config[:back] + "/" + a["href"]
			end
		end
		
	end
	
	def self.import_translation_pack file
		if File.file?(file) and file=~/[a-z]{2}\.gzip$/
			resp = RestClient.post @urls['AdminTranslations'], :file => File.new(file, 'rb'), 'theme[]' => 'default', 'submitImport' => 'Import' do |response, request, result, &block|
				if [301, 302, 307].include? response.code
					#puts response.headers
					response = RestClient.get(@config[:back] + "/" + response.headers[:location])
				else
					response.return!(request, result, &block)
				end
			end
			@body = Nokogiri::HTML(resp)
			
			if @body.css('div.conf').count == 1
				return true
			end
			return false
		else
			return false
		end
	end
	
	def self.list_languages
		self.goto 'AdminTranslations'
		@body.to_s.scan(/javascript:chooseTypeTranslation\('([a-z]{2})'\)/).map{|m| m[0]}
	end
	
	def self.export_language iso, output_dir=nil
		response = RestClient.post @urls['AdminTranslations'], 'theme' => 'default', 'iso_code' => iso, 'submitExport' => 'Export'
		if response.code == 200
			if output_dir and File.directory?(output_dir)
				File.open("#{output_dir}/#{iso}.gzip","w") do |file|
					file.puts response
				end
			end
			return true
		else
			return false
		end
	end
	
	def self.authenticate
	
		response = RestClient.post @config[:back]+"/ajax-tab.php", {
			ajax: 1,
			controller: 'AdminLogin',
			submitLogin: 1,
			passwd: @config[:password],
			email: @config[:user],
			redirect: 'AdminHome'
		}
		
		if response.code == 200
			data = JSON.parse(response)
			if data['hasErrors']
				puts data['errors'].join(', ')
				return false
			else			
				@cookies = cookies = response.cookies
				#puts "Cookies:\n#{cookies}"
				self.goto (@config[:back]+"/"+data['redirect'])
				
				return true
			end
		else
			return false
		end
	end
	
end
