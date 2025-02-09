require 'ruby-prof'

result = RubyProf::Profile.profile do
  stations = {}
  file = File.foreach('measurements.txt') do |line|
    station, temperature = line.split(';')

    stations[station] ||= Ractor.new(station) do |name|

      #setup local storage for Ractor
      self[:name] = name
      self[:min] = 0
      self[:max] = 0
      self[:sum] = 0
      self[:count] = 0

      loop do
        case Ractor.receive
        in :add, str_temp
          temp = str_temp.to_f
          
          self[:min] = temp if temp < self[:min]
          self[:max] = temp if temp > self[:max]

          self[:sum]   += temp
          self[:count] += 1
          
        in :get, asker
          asker.send([self[:name], "#{self[:min]}/#{self[:sum] / self[:count]}/#{self[:max]}"])
          break
        in msg
          "unknown message '#{msg}' was received"
        end
      end
    end

    stations[station].send([:add, temperature])
  end

  stations.each{|name, ractor| ractor.send([:get, Ractor.current()])}
  
  results = {}
  printed = false
  stations.length.times do
    station, values = Ractor.receive()
    if !printed
      puts "#{station}=#{values}"
      printed = true
    end
  end
end

File.open "iteration3-profile-stack.html", 'w+' do |file|
  RubyProf::CallStackPrinter.new(result).print(file)
end

# 100 million rows. :/
# Executed in  519.38 secs    fish           external
#    usr time    8.65 mins    0.08 millis    8.65 mins
#    sys time   18.10 mins    1.31 millis   18.10 mins
