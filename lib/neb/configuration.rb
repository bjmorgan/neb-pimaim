class Configuration

	include Additionalmath

	attr_accessor :species
	attr_accessor :springs
	attr_reader :number
	attr_reader :cell
	attr_reader :nions
	attr_reader :smass
	attr_reader :spring_forces
	attr_reader :potential_energy

	@@nconfigs = 0
	@@configs = []
	@@calculation_type = PIMAIM

	def initialize( nions, coordinates, cell )
		smass = 1 # it probably doesn't matter what the ion masses are
		@nions = nions
		@cell = cell
		set_species_from_coordinates( smass, coordinates )
		@number = @@nconfigs
		@springs = []
		@@nconfigs += 1
		@@configs << self
		@previous_kinetic_energy = 0.0
		run_dir = $dir_prefix + @number.to_s
		@calculation = @@calculation_type.new( run_dir, self )
	end

	def connect_to( config2 )
		spring = Spring.new( self, config2 )
		@springs << spring
		config2.springs << spring
	end

	def neighbouring_images
		return [ @@configs[@number-1], @@configs[@number+1] ]
	end

	def tangent # Uses the definition of tangent from NEB book chapter
		return ( springs[0].vector.unit_vector + springs[1].vector.unit_vector ).unit_vector 
	end

	def calculate_spring_forces
		@spring_forces = case @number
		when 0 # first image
			springs[0].force_on( self )
		when @@nconfigs - 1 # last image
			springs[0].force_on( self ) * -1.0
		else # images to be relaxed
			springs[1].force_on( self ) + springs[0].force_on( self )
		end
	end

	def projected_spring_force( step )
		if ( $options[:climbing] ) and ( self === Configuration.highest_image )
			return real_forces( step ).parallel_to( tangent ) * -1.0
		else
			return @spring_forces.parallel_to( tangent )
		end
	end

	def projected_real_force( step )
		return real_forces( step ).perpendicular_to( tangent )
	end

	def real_forces( step )
		return Vector.new( ions.collect{ |ion| ion.force[ step ] } )
	end

	def total_force( step )
		return  ( projected_real_force( step ) + projected_spring_force( step ) + correcting_force )
	end

	def correcting_force
		return ( switching_function( this_cos_theta ) * @spring_forces.perpendicular_to( tangent ) )
 	end

 	def switching_function( cosine_theta )
 		if ( arccos(cosine_theta).abs > Math::PI / 2.0 )
 			return 1.0
 		else
			return ( 0.5 * ( 1.0 + Math.cos(Math::PI * cosine_theta) ) )
		end
 	end

	def this_cos_theta
		case springs.length
		when 1
			return nil
		when 2
			return cos_theta( springs[0].vector, springs[1].vector )
		end
	end

	def converged?
		return total_force(0).count{ |f| f.norm >= $options[:convergence] } == 0
	end

	def set_species_from_coordinates( smass, coordinates )
		@species = @nions.inject([]) do |array, num| 
			array << Species.new( smass, (1..num).collect{ |n| Ion.new( smass, coordinates.shift, @cell ) } )
		end
	end

	def interpolate
		limage = @@configs[0..@number-1].select{ |config| !config.interpolated_image? }[-1]
		rimage = @@configs[@number+1..-1].select{ |config| !config.interpolated_image? }[0]

		@nions = limage.nions
		@cell = limage.cell # assumes all cells are the same.
		smass = 1

		proportional_distance = ( @number - limage.number ).to_f / ( rimage.number - limage.number ).to_f
		lcoordinates = limage.coordinates
		rcoordinates = rimage.coordinates
		new_coordinates = lcoordinates.zip( rcoordinates ).map{ |i,j| i + limage.cell.dr(i,j) * proportional_distance } 
		set_species_from_coordinates( smass, new_coordinates )
	end

	def self.new_interpolated_image
		self.new( [], nil, nil )
	end

	def interpolated_image?
		return @species.empty?
	end

	def setup_calculation
		@calculation.setup_calculation
	end

	def setup_calculation_at_next_timestep
		@calculation.setup_next_calculation
	end

	def dr( r1, r2 )
		return @cell.dr( r1, r2 )
	end

	def ions
		return @species.collect{ |spec| spec.ions }.flatten
	end

	def coordinates
		return Vector.new( ions.collect{ |ion| ion.r } )
	end

	def run_calculation
		@calculation.run
	end

	def read_data( step )
		@potential_energy = @calculation.read_eng
		forces = @calculation.read_forces( step )
		ions.zip( forces ).each{ |ion, f| ion.force[ step ] = f }
	end

	def kinetic_energy
		return ions.inject(0) {| sum, ion| sum += ion.kinetic_energy }
	end

	def total_energy
		return @potential_energy + kinetic_energy
	end

	def update_ion_forces( step )
		ions.zip( total_force( step ) ).each{ |ion, f| raise if f.size != 3; ion.force[ step ] = f }
	end

	def each_ion( method )
		ions.each{ |ion| ion.send( method ) }
	end
	
	def calculate_ion_velocities_at_t_plus_dt
		each_ion( :calculate_velocity_at_t_plus_dt )
	end

	def calculate_ion_positions_at_t_plus_dt
		each_ion( :calculate_position_at_t_plus_dt )
	end

	def zero_velocities
		each_ion( :zero_velocities )
	end

	def update_step
		each_ion( :update_step )
		@previous_kinetic_energy = kinetic_energy
	end

	def is_endpoint?
		return ( ( @number == 0 ) or ( ( @number + 1 ) == @@nconfigs ) )
	end

	def self.connect_springs
		@@configs[0..-2].zip(@@configs[1..-1]){ |i, j| i.connect_to( j ) }
	end

	def self.calculate_spring_forces
		@@configs.each{ |config| config.calculate_spring_forces }
	end

	def self.highest_image
		@@configs[1..-2].max
	end

	def <=>( other )
		potential_energy <=> other.potential_energy
	end

	def self.barrier_height
		max_energy = self.highest_image.potential_energy
		min_endpoint_energy = [@@configs[0], @@configs[-1]].min.potential_energy
		return max_energy - min_endpoint_energy
	end

	def output
		if self.is_endpoint?
			return "Image %3i  ::  -----  ::  %6.3f  ::  -----  ::  --------" % [ @number, relative_energy ]
		else
			return "Image %3i  ::  %.3f  ::  %6.3f  ::  %.3f  ::  %.2e" % [ @number, @springs[0].length, relative_energy, this_cos_theta, gradient ]
		end
	end

	def gradient
		return total_force(0).norm
	end

	def relative_energy
		(potential_energy - @@configs[0].potential_energy)*$hartree_to_eV
	end

	def self.initial_step
		each_config( :setup_calculation, :parallel )
		each_config( :run_calculation, :parallel )
		each_config( :read_data, :not_parallel, 0 )
		Spring.update_springs
		self.calculate_spring_forces
		each_mobile_config( :update_ion_forces, :not_parallel, 0 )
	end

	def self.next_step
		each_mobile_config( :calculate_ion_positions_at_t_plus_dt, :not_parallel )
		each_mobile_config( :setup_calculation_at_next_timestep, :not_parallel )
		each_mobile_config( :run_calculation, :parallel )
		each_mobile_config( :read_data, :not_parallel, 1)
		Spring.update_springs
		self.calculate_spring_forces
		each_mobile_config( :update_ion_forces, :not_parallel, 1)
		each_mobile_config( :calculate_ion_velocities_at_t_plus_dt, :not_parallel )
		each_mobile_config( :update_step, :not_parallel )
		self.report_diagnostics if $options[:diagnostic]
	end

	def self.each_config( method, allow_parallel, args = nil )
		if $options[:parallel] and allow_parallel == :parallel
			Parallel.each( @@configs, :in_processes => $options[:nprocs] ){ |config| config.send( method, *args ) }
		else
			@@configs.each{ |config| config.send( method, *args ) }
		end
	end

	def self.each_mobile_config( method, allow_parallel, args = nil )
		if $options[:parallel] and allow_parallel == :parallel
			Parallel.each( @@configs[1..-2], :in_processes => $options[:nprocs] ){ |config| config.send( method, *args ) }
		else
			@@configs[1..-2].each{ |config| config.send( method, *args ) }
		end
	end

	def self.output
		@@configs.collect{ |config| config.output }
	end

	def self.converged
		return @@configs[1..-2].count { |config| config.converged? } == @@configs.length - 2
	end

	def self.report_diagnostics
		@@configs[ $options[:diagnostic_image] ].report_diagnostics
	end

	def report_diagnostics
		puts "Image #{@number}; Ion 1 => forces"
		puts "lspring: " + springs[0].force_on( self )[0].join(' ')
		puts "rspring: " + springs[1].force_on( self )[0].join(' ')
		puts "springs: " + spring_forces[0].join(' ')
		puts "correction: " + correcting_force[0].join(' ')
		puts "tforces: " + ions[0].force[0].join(' ')
		puts
	end

end