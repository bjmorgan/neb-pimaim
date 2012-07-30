module Additionalmath

	def theta( v1, v2 )
		arccos( cos_theta( v1, v2 ) )
	end

	def arccos( x )
		Math.atan2( Math.sqrt( 1.0 - x*x ), x )
	end

	def cos_theta( v1, v2 )
		return [ v1.unit_vector.dot_product( v2.unit_vector ), 1.0 ].min # to prevent rounding errors giving > 1.0
	end

end