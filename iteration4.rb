require 'ruby-prof'

stations = {}
result = RubyProf::Profile.profile do
  file = File.foreach('measurements.txt') do |line|
    station, temperature = line.split(';')
    Ractor.make_shareable(station)
    Ractor.make_shareable(temperature)

    if stations[station]
      Ractor.make_shareable([:add, temperature]).then do
        stations[station].send(it)
      end
    else
      stations[station] = Ractor.new(station, temperature) do |name, first_temp|

        ft = first_temp.to_f
        #setup local storage for Ractor
        self[:name] = name
        self[:min] = ft
        self[:max] = ft
        self[:sum] = ft
        self[:count] = 1

        loop do
          case Ractor.receive
          in :add, next_temp
            nt = next_temp.to_f
            
            self[:min] = nt if nt < self[:min]
            self[:max] = nt if nt > self[:max]

            self[:sum]   += nt
            self[:count] += 1
            
          in :get_values, asker
            payload = "#{self[:min]}/#{self[:sum] / self[:count]}/#{self[:max]}"
            Ractor.make_shareable([self[:name], payload]).then do
              asker.send(it)
            end
          in :get_count, asker
            Ractor.make_shareable([self[:name], self[:count]]).then do
              asker.send(it)
            end
            break
          in msg
            "unknown message '#{msg}' was received"
          end
        end
      end
    end
  end

  stations.each do |name, ractor|
    Ractor.make_shareable([:get_values, Ractor.current()]).then do
      ractor.send(it)
    end
  end
  
  stations.length.times do |n|
    station, values = Ractor.receive()
    if n == 1
      puts "#{station}=#{values}"
    end
  end
end

stations.each do |name, ractor|
    Ractor.make_shareable([:get_count, Ractor.current()]).then do
      ractor.send(it)
    end
  end

readings = 0
stations.length.times do
  station, count = Ractor.receive()
  readings += count
end

puts "run on #{readings} readings"

File.open "iteration4-profile-stack.html", 'w+' do |file|
  RubyProf::CallStackPrinter.new(result).print(file)
end

# 100 million rows. :/
# Executed in  519.38 secs    fish           external
#    usr time    8.65 mins    0.08 millis    8.65 mins
#    sys time   18.10 mins    1.31 millis   18.10 mins
