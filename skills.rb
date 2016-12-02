require 'yaml'
require 'pp'

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
  end
end

File.open("skills.yaml","w+") << YAML.dump(data)
