class Vector < Array

	# def dimensions
	# 	if self[0].is_a?( Numeric ) then return self.size end
	# 		return self[0].size, self.size
	# end

	def +( a )
		if a.is_a?( Numeric ) # add scalar
			return Vector.new( self.map{ |i| i + a } )
		elsif a.is_a?( Vector ) # vector addition
			# check_equal_dimensions(a)
			return Vector.new( self.zip(a).map{ |i,j| i + j } )
		else
			raise "not a valid vector addition"
		end
	end

	def -( a )
		if a.is_a?( Numeric ) # subtract scalar
			return Vector.new( self.map{ |i| i - a } )
		elsif a.is_a?( Vector ) # vector subtraction
			# check_equal_dimensions(a)
			return Vector.new( self.zip(a).map{ |i,j| i - j } )
		else
			raise "not a valid vector subtraction"
		end
	end

	def *( a )
		if a.is_a?( Numeric ) # multiply scalar
			return Vector.new( self.map{ |i| i * a } )
		elsif a.is_a?( Vector ) # vector multiplication
			# check_equal_dimensions(a)
			Vector.new( self.zip(a).map{ |i,j| i * j } )
		else
			raise "not a valid vector multiplication"
		end
	end

	def /( a )
		if a.is_a?( Numeric ) # divide by scalar
			return Vector.new( self.map{ |i| i / a } )
		elsif a.is_a?( Vector ) # vector division
			# check_equal_dimensions(a)
			Vector.new( self.zip(a).map{ |i,j| i / j } )
		else
			raise "not a valid vector division"
		end
	end

	def coerce( other )
		return self, other
	end

	def dot_product( a )
		sum = 0
		v1 = self.flatten
		v2 = a.flatten
		for i in 0...v1.size
			sum += v1[i] * v2[i]
		end
		return sum	
	end

	def norm
		Math.sqrt( dot_product( self ) )
	end

	def unit_vector
		return self / norm
	end

	def normalised
		unit_vector
	end

	def parallel_to( v )
		# check_equal_dimensions(v)
		return self.dot_product( v.unit_vector ) * v.unit_vector
	end

	def perpendicular_to( v )
		# check_equal_dimensions(v)
		return self - self.parallel_to(v)
	end

end