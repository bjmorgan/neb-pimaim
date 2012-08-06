class Ion

	def initialize( mass, r, cell )
		@mass = mass
		@r = []
		@force = Vector.new( [ Vector.new([ 0.0, 0.0, 0.0]), Vector.new([ 0.0, 0.0, 0.0]) ] )
		@a = []
		@v = []
		@cell = cell

		@r[0] = @cell.pbc_orthorhombic( r )						# position vector
		zero_velocities 															# velocity vector. Inititalise to zero
	end

	def calculate_position_at_t_plus_dt
		@r[1] = @r[0] + ( @v[0] * dt ) + ( a[0] * 0.5 * dt**2 )
		@r[1] = @cell.pbc_orthorhombic( @r[1] )
		return @r[1]
	end

	def force
		return @force
	end

	def force=(f)
		@force = f
	end

	def dt
		return $options[:timestep]
	end

	def a
		return @force / @mass
	end

	def r
		return @r[0]
	end

	def r_t
		return @r[1]
	end

	def calculate_velocity_at_t_plus_dt
		@v[1] = @v[0] + (a[0] + a[1]) * 0.5 * dt
	end

	def update_step
		@r[0] = @r[1]
		@v[0] = @v[1]
		@force[0] = @force[1]
		if @v[0].dot_product( @force[0].unit_vector ) > 0
			@v[0] = @v[0].dot_product( @force[0].unit_vector ) * @force[0].unit_vector
		else
			zero_velocities
		end
	end

	def kinetic_energy
		return 0.5 * @mass * @v[0].norm ** 2
	end

	def zero_velocities
		@v[0] = Vector.new( [ 0.0, 0.0, 0.0 ] )
	end

end