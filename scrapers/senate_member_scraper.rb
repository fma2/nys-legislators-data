require 'rubygems'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'csv'


def scrape_contact_information(member, site)
	member_contact_doc = Nokogiri::HTML(open(site)).css('.location-locations-wrapper > .location')

	member_contact_array = Array.new
	
	member_contact_doc.map do |info|
		contact_hsh = { 
			:address_title => info.css('.adr > .fn').text.strip,
			:street_address => info.css('.adr > .street-address').text.strip.split("\n").map(&:strip).join(" "),
			:locality => info.css('.adr > .locality').text.strip,
			:region => info.css('.adr > .region').text.strip,
			:postal_code => info.css('.adr > .postal-code').text.strip,
			:country => info.css('.adr > .country-name').text.strip,
			:phone => info.css('.adr > .tel > .value').children.text,
		}

		if info.css('.adr > .tel > span').children[1] == nil
			member_contact_array << contact_hsh
		else
			contact_hsh[:fax] = info.css('.adr > .tel > span').children[1].text
			member_contact_array << contact_hsh
		end
	end
	member_contact_array
end

def scrape_member_email(site)
	member_email = Nokogiri::HTML(open(site)).css('.senator-contact-page > .spamspan').text.gsub!(' [at] ', '@').gsub!(' [dot] ', '.')
end


def scrape_all_information(doc)
	sm_array = Array.new

	doc.map do |member|
		member_contact_site = 'http://www.nysenate.gov' + member.css('.views-field-field-last-name-value > .field-content > .contact > a').attr('href').text
		
		member_contact_array = scrape_contact_information(member, member_contact_site)
		member_email = scrape_member_email(member_contact_site)

		full_name_array = member.css('.views-field-field-last-name-value > .field-content a').children.first.text.split(",").map(&:strip)

		sm_info_hsh = Hash.new
		sm_info_hsh[:photo] = member.css('.views-field-field-profile-picture-fid > .field-content img').attr('src').text
		sm_info_hsh[:first_name] = full_name_array[1]
		sm_info_hsh[:last_name] = full_name_array[0]
		sm_info_hsh[:full_name] = "#{full_name_array[1]} #{full_name_array[0]} #{full_name_array[2]}"
		sm_info_hsh[:email] = member_email
		sm_info_hsh[:contact_link] = 'http://www.nysenate.gov' + member.css('.views-field-field-last-name-value > .field-content > .contact > a').attr('href').text
		sm_info_hsh[:district] = member.css('.views-field-field-senators-district-nid > .field-content').children.map(&:text)[0]
		sm_info_hsh[:site] = 'http://www.nysenate.gov' + member.css('.views-field-field-last-name-value > .field-content > a').attr('href').text
		sm_info_hsh[:contact] = member_contact_array
		sm_info_hsh[:social_rss] = 'http://www.nysenate.gov' + member.css('.views-field-field-senators-district-nid > .field-content > #senator-buttons > #social_buttons > .rss').attr('href').text
		
		if member.css('.views-field-field-senators-district-nid > .field-content > #senator-buttons > #social_buttons > .facebook').text == ""
			puts member.css('.views-field-field-senators-district-nid > .field-content > #senator-buttons > #social_buttons > .facebook')
			sm_info_hsh[:social_facebook] = ""	
		else
			sm_info_hsh[:social_facebook] = member.css('.views-field-field-senators-district-nid > .field-content > #senator-buttons > #social_buttons > .facebook').attr('href').text
		end

		if member.css('.views-field-field-senators-district-nid > .field-content > #senator-buttons > #social_buttons > .twitter').text == "" 
			sm_info_hsh[:social_twitter] = ""	
		else
			sm_info_hsh[:social_twitter] = member.css('.views-field-field-senators-district-nid > .field-content > #senator-buttons > #social_buttons > .twitter').attr('href').text
		end

		sm_array << sm_info_hsh
	end
	sm_array
end

sm_doc = Nokogiri::HTML(open("http://www.nysenate.gov/senators")).css('.view-content > .views-row')
sm_json = scrape_all_information(sm_doc)

File.open("../public/nys-senate-members-2015.json","w") do |f|
  f.write(sm_json.to_json)
end