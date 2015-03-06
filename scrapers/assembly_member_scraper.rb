require 'rubygems'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'csv'

def scrape_all_information(doc)
	am_array = Array.new
	doc.map do |member|
		albany_office = member.css('.leader-info > .mem-address > .float-right').children.map(&:text).map(&:strip)
		do_office = member.css('.leader-info > .mem-address > .float-left').children.map(&:text).map(&:strip)
		title = member.css('.leader-info > strong').text #not exactly what i want
		district = title.split(" -- ")[1]
		full_name_array = member.css('.leader-info > strong > a').text.split(" ")
		am_array << {
			:photo => member.css('.mem-pic img').attr('src').text,
			:first_name => full_name_array[0],
			:last_name => full_name_array[1],
			:full_name => full_name_array.join(" "),
			:email => member.css('.leader-info > .mem-email > a').text,
			:district => district,
			:site => "http://assembly.state.ny.us" + member.css('.leader-info > strong > a').attr('href'),
			:albany_office_address => "#{albany_office[0]} " + "#{albany_office[2]}",
			:albany_office_no => albany_office[4],
			:do_office_address => "#{do_office[0]} " + "#{do_office[2]}",	
			:do_office_no => do_office[4],
		}
	end
	am_array
end

am_doc = Nokogiri::HTML(open("http://assembly.state.ny.us/mem/")).css('.memleadfont > li')
am_json = scrape_all_information(am_doc)

File.open("../public/nys-assembly-members-2015.json","w") do |f|
  f.write(am_json.to_json)
end

