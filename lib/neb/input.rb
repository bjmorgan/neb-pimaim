class Input < String

	@@keywords = %w(interpolate)

	def read_string
		self.split[0]
	end

	def read_string_with_args
		[ self.split[0], self.split[1..-1] ]
	end

	def read_int
		self.split[0].to_i
	end

	def is_comment?
		self[0].chr == '#'
	end

	def keyword?
		@@keywords.include?( self.split[0] )
	end

end

def read_input( filename )
	input = File.new( filename, 'r' ).readlines.map{ |line| Input.new( line.strip ) }
	input.delete_if{ |line| line.empty? }        # do not read empty lines
	input.delete_if{ |line| line.is_comment? }   # do not read comments (lines that start with # => )

	executable = input.shift.read_string
	setup_dir = input.shift.read_string
	nspecies = input.shift.read_int
	nconfigs = input.shift.read_int
	configs = (0...nconfigs).inject([]) do |list, c_index|

		if input[0].keyword? then
			keyword, args = input.shift.read_string_with_args
			case keyword
			when 'interpolate'
				args[0].to_i.times{ |i| list << Configuration.new_interpolated_image }
			end
		end
		
		nions = (0...nspecies).inject([]) do |array, n_index| 
			array << input.shift.read_int
		end

		posfile_name = input.shift.read_string	
		cellfile_name = input.shift.read_string

		posfile_path = setup_dir + "/" + posfile_name
		cellfile_path = setup_dir + "/" + cellfile_name
		coordinates = positions_from( posfile_path )
		cell = lattice_from( cellfile_path )
		list << Configuration.new( nions, coordinates, cell )
	end

	configs.each do |config|
		if config.interpolated_image?
			config.interpolate
		end
	end

	return setup_dir, executable
end

def positions_from( file )
	posfile = File.new( file, 'r' )
	posfile.readlines.map{ |line| Vector.new( line.split.map{ |s| s.to_f } ) }
end

def lattice_from( file )
	cellfile = File.new( file, 'r' ).readlines.map{ |line| line.strip.split.map{ |e| e.to_f } }
	lattice = Matrix.new( cellfile[0...3] )
	cell_lengths = Vector.new( cellfile[3...6].flatten )
	Cell.new( lattice, cell_lengths )
end