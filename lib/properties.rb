require 'yaml'

class Properties

	def get key
		parsed = YAML.load(File.open(Rails.root.join('config', 'winasl.yml')))
	
		parsed[key]
	end
end