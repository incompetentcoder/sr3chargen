require 'yaml'
require 'pp'
require 'pry'
require 'set'
weps=YAML.load_file('gearyaml')
weps2=(weps.collect{|x| x[1][:Type][2]}.compact + weps.collect{|x| x[1][:Type][1]}.compact).to_set
a=File.open("skills").read
data = {}
%w(Body Quickness Strength Charisma Intelligence Willpower Reaction).each do |x|
  data[x.to_sym] = {}
  lines = a[/@#{x}[\S\s]*?\n\n\n/]
  skills = lines.scan(/@.*/) - ["@"+x]
  pp skills
  skills.each do |y|
    skillname = y[1..-1].to_sym
    skill = a[/#{y}[\S\s]*?\n\n/]
    skill.chomp!.chomp!
    data[x.to_sym][skillname] = {}
    data[x.to_sym][skillname][:Desc] = skill.split("\n")[1]
    data[x.to_sym][skillname][:Specialization] = skill.split("\n").length > 2 ? skill.split("\n")[2].split(",") : []
    if weps2.include? skillname
      data[x.to_sym][skillname][:Specialization] =
        weps.collect{|x| x[1][:Stats][:Name].split('(')[0] if x[1][:Type][1] == skillname || x[1][:Type][2] == skillname}.compact
    elsif skillname == :"Gyrojet Pistols"
      data[x.to_sym][skillname][:Specialization] =
        weps.collect{|x| x[1][:Stats][:Name].split('(')[0] if x[1][:Stats][:Name] =~ /gyrojet/i}.compact
    elsif skillname =~ /pistol/i
      data[x.to_sym][skillname][:Specialization] =
        weps.collect{|x| x[1][:Stats][:Name].split('(')[0] if x[1][:Type][2].to_s =~ /pistol/i}.compact
    elsif skillname == :"Laser Weapons"
      data[x.to_sym][skillname][:Specialization] =
        weps.collect{|x| x[1][:Stats][:Name].split('(')[0] if x[1][:Stats][:Name] =~ /laser/i}.compact
    elsif skillname == :"Edged Weapons"
      data[x.to_sym][skillname][:Specialization] =
        weps.collect{|x| x[1][:Stats][:Name].split('(')[0] if x[1][:Type][2] == :"Edged"}.compact
    elsif skillname == :"Pole Arms/Staves"
      data[x.to_sym][skillname][:Specialization] =
        weps.collect{|x| x[1][:Stats][:Name].split('(')[0] if x[1][:Type][2] == :"Polearm"}.compact
    end
  end
end

File.open("skills.yaml","w+") << YAML.dump(data)
