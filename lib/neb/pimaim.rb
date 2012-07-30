class PIMAIM

	@@executable = 'pimaim_serial.exe'
	@@force_file = 'forces.out'
	@@eng_file = 'engtot.out' # this should really be the potential energy file
	@@input_files = %w(cf.inpt crystal_cell.inpt potential.inpt runtime.inpt)

	def initialize( run_dir, configuration )
		@run_dir = run_dir
		@configuration = configuration
	end

	def path( filename )
		return @run_dir + '/' + filename
	end

	def setup_calculation
		FileUtils.mkdir( @run_dir )
		@@input_files.each { |file| FileUtils.cp( $setup_dir + '/' + file, @run_dir ) }
		mk_rstfile( false )
	end

	def setup_next_calculation
		run_in_dir( 'rm *.out*' )
		mk_rstfile( true )
	end

	def mk_rstfile( next_step )
		restart_file = File.new( path('restart.dat'), 'w' )
		restart_file.puts( "T\nF\nF\nF\n")
		if next_step
			restart_file.puts( @configuration.ions.collect{ |ion| ion.r_t.join(' ') }.join("\n") )
		else
			restart_file.puts( @configuration.ions.collect{ |ion| ion.r.join(' ') }.join("\n") )
		end
		restart_file.puts( @configuration.cell.to_s )
		restart_file.close
	end

	def run_in_dir( command )
		Dir.chdir( @run_dir ) 
		%x{ #{command} } 
		Dir.chdir( '..' )
	end

	def run
		run_in_dir( @@executable )
	end

	def read_eng
		return File.open( path(@@eng_file) ).readline.split[2].to_f
	end

	def read_forces( step )
		forces = File.open( path(@@force_file) )
		to_return = forces.readlines.map{ |line| Vector.new( line.split.map{ |e| e.to_f } ) } 
		return to_return
	end

end