class Cell

	def initialize( h, cell_lengths )
		@h = h
		@cell_lengths = cell_lengths
	end

	def to_s
		output = @h.collect{ |row| row.join(' ') }
		output << @cell_lengths
	end

	def dr( r1, r2 ) # Where r1 and r2 are each length 3 Vectors
		dr_orthorhombic( r1, r2 )
	end

	def dr_orthorhombic( r1, r2 )
		return Vector.new( (r2 - r1).zip(@cell_lengths).collect do |dr, length|
			dr -= length if ( dr >  length / 2.0 )
			dr += length if ( dr < -length / 2.0 )
			dr
		end )
	end

end