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
        if e < 22
          cyber[name][header[e].to_sym]=d
        end
			end
		end
	end
end
				








cyber=Hash.new

parsecyber("cyberware",cyber)
File.open("cyberyaml",'w+') << YAML.dump(cyber)

