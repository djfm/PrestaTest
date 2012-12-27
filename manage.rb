#!/usr/bin/ruby

require_relative 'prestashop.rb'

config = ARGV[0].to_s

if config.empty?
	puts "Select a config!"
	exit
end

unless PrestaShop.connect config
	puts "Could not connect to PS!"
	exit
end

if ARGV[1] == 'import'
	if ARGV[2] == 'all'
		if File.directory? d=ARGV[3]
			ok = nok = 0
			Dir.entries(d).each do |entry|
				if File.basename(entry) =~ /[a-z]{2}\.gzip$/
					res = PrestaShop.import_translation_pack (p="#{d}/#{entry}")
					if res
						ok += 1
						puts "OK: #{p}"
					else
						nok +=1
						puts "Error importing pack: '#{p}'!!!"
					end
				end
			end
			puts "Succesfully imported #{ok} packs of #{ok+nok}!!"
			if nok > 0
				puts "THERE WERE #{nok} ERRORS!!"
			end
		else
			puts "Not a directory!"
		end
	else
		if File.file? ARGV[2]
			res = PrestaShop.import_translation_pack ARGV[2]
			puts res ? "Success!" : "Error!!"
		else
			puts "Not a file!"
		end
	end
end
