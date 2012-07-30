class Spring

	@@n_springs = 0
	@@springs = []

	attr_reader :number
	attr_reader :ends
	attr_reader :vector

	def initialize( image_i, image_j )
		@ends = [ image_i, image_j ]
		@number = @@n_springs
		@@n_springs += 1
		@@springs << self
		set_vector
	end

	def length_squared
		vector.flatten.inject(0) { |sum, element| sum += element * element }
	end

	def set_vector # vector points from @ends[0] --> @ends[1] (these should be image n -> n+1 )
		@vector = Vector.new( @ends[0].ions.zip( @ends[1].ions ).collect{ |ion_i, ion_j| dr( ion_i.r, ion_j.r ) } )
	end

	def dr( r1, r2 ) # in the future it would be good to have dynamical cell parameters, linked by further spring components
		@ends[0].dr( r1, r2 )
	end

	def energy
		0.5 * $options[:spring_constants] * length_squared
	end

	def force
		to_return = -$options[:spring_constants] * vector
		raise if to_return[0].size != 3
		return to_return
	end
	private :force

	def points_to
		return @ends[1]
	end

	def force_on( config )
		if ( config === points_to ) then
			return force
		else
			return force * -1.0
		end
	end

	def self.number_of_springs
		@@n_springs
	end

	def self.springs
		@@springs
	end

	def self.update_springs
		@@springs.each{ |spring| spring.set_vector }
	end

	def self.total_energy
		@@springs.inject(0) { |sum, spring| sum += spring.energy }
	end

	def length
		return Math.sqrt( length_squared )
	end

end