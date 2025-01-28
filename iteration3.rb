require 'ruby-prof'

result = RubyProf::Profile.profile do
  stations = {}
  file = File.foreach('measurements.txt') do |line|
    station, temp = line.split(';')
    
    stations[station] ||= Ractor.new do |name|

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

    stations[station].send([:add, temp])
  end

  stations.each{|station| station.send([:get, Ractor.current])}
  
  ractors = stations.values
  while ractors.length > 0 do
    
    ractor, [name, values] = Ractor.select(*ractors)
    puts "#{station}=#{measurements[:min]}/#{measurements[:mean]}/#{measurements[:max]}"
    ractors.delete(ractor)
  end
end

File.open "iteration3-profile-stack.html", 'w+' do |file|
  RubyProf::CallStackPrinter.new(result).print(file)
end
