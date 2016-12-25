require 'yaml'
require 'pp'

def parsecyber(name,cyber)
	a=File.open(name,'r').read
	a.split("\n\n").each do |b|
		header = b[0 .. b.index("\n")-1].split(" ¬")
		start = b.index("\n",b.index("\n")+1)+1
		type = b[b.index("\n")+1 .. b.index("\n",b.index("\n")+1) -1]
		b[start .. -1].split("\n").each do |c|
      name=c.split(" ¬")[0].to_sym
			cyber[name]=Hash.new
			c.split(" ¬").each_with_index do |d,e|
        if e < 23
          unless header[e] == "Stats"
            cyber[name][header[e].to_sym]=d.to_s unless d == ''
          else
            stuff = {}
            stats = d.split(";")
            stats.each do |stat|
              base = stat.split("[")[0]
              stat.split("[")[1].delete("]").split(",").each do |values|
                value = values.split("|")
                if value[1]
                  stuff[base.to_sym]={} unless stuff.has_key?(base.to_sym)
                  value2,bonus = value[1].split(":")
                    if bonus
                      stuff[base.to_sym][value[0].to_sym] = {}
                      stuff[base.to_sym][value[0].to_sym][value2.to_sym] = bonus.to_i
                    else
                      stuff[base.to_sym][value[0].to_sym] = value2.to_sym
                    end
                else
                  value,bonus = value[0].split(":")
                  if bonus
                    stuff[base.to_sym] = {} unless stuff.has_key?(base.to_sym)
                    stuff[base.to_sym][value.to_sym] = bonus.to_i
                  else 
                    stuff[base.to_sym] = value.to_sym
                  end
                end
              end
            end
            cyber[name][header[e].to_sym] = stuff
          end 
        end
			end
		end
	end
end
				








cyber=Hash.new

parsecyber("cyberware",cyber)
File.open("cyberyaml",'w+') << YAML.dump(cyber)

