class Species

	attr_reader :ions
	attr_reader :mass

	def initialize( mass, ions )
		@mass = mass
		@ions = ions
	end

end