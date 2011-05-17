require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'date'
require 'pp'
require 'time'
require 'ri_cal'

urls = {
  'Primavera a la Ciutat' => 'http://www.primaverasound.com/ps/?page=primaveraciutat&lang=en', 
  'Poble Espanyol' => 'http://www.primaverasound.com/ps/?page=poble-espanyol&lang=en', 
  'Parc del Forum' => 'http://www.primaverasound.com/ps/?page=parc-del-forum&lang=en'
}

all_events = {}

urls.each do |name, url|
  all_events[name] = []
  
  page = Nokogiri::HTML(open(url))
  page.css('h3.conciertoTitulo').each_with_index do |html_date, index|
    date = Date.parse(' 2011 ' + html_date.text)
    table = page.css('table.tablesorter')[index]
    table.css('tr').each do |line|
      tds = line.css('td')
      next if tds.empty? # header

      artist = tds[0].text
      venue = "#{tds[1].text}, #{name}"
      if tds[2].text.strip != ''
        str_time = date.to_s + 'T' + tds[2].text.gsub('h', '')
        time = Time.parse(str_time)
        if time.hour < 6
          time = time + (24*60*60)
        end        
        dtstart = time.with_floating_timezone
        dtend   = (time + (60 * 60)).with_floating_timezone
      else
        dtstart = date
        dtend   = date + 1
      end

      event = {}
      event[:summary]  = "#{artist} at #{venue}"
      event[:location] = "#{venue}, Barcelona, Spain"
      event[:dtstart]  = dtstart
      event[:dtend]    = dtend
      all_events[name] << event
    end
  end
end


ical_all_events = RiCal::Component::Calendar.new

all_events.each do |name, events|
  ical = RiCal::Component::Calendar.new
  
  events.each do |event|
    ical_event = RiCal::Component::Event.new
    ical_event.dtstart  = event[:dtstart]
    ical_event.dtend    = event[:dtend]
    ical_event.summary  = event[:summary]
    ical_event.location = event[:location]

    ical_all_events.events << ical_event
    ical.events << ical_event
  end

  File.open("#{name.downcase.gsub(' ', '_')}.ics", 'w') do |f|
    f.puts ical.to_s
  end
  
end

File.open('primavera_sound_2011.ics', 'w') do |f|
  f.puts ical_all_events.to_s
end


  

