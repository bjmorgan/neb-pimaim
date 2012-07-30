def write_to_output_file
	to_output = ( Configuration.output )
	File.open( $options[:output], 'w') { |f| f.write( to_output ) }
end

$hartree_to_eV = 27.211396132
$dir_prefix = 'image'

$options = set_options
%x{ rm -rf #{$dir_prefix}* } if $options[:new_calculation]

$setup_dir, $executable = read_input( $options[:input] )

Configuration.connect_springs
Configuration.initial_step
Configuration.output
puts "barrier height = %.4f eV " % (Configuration.barrier_height * $hartree_to_eV)

# begin dynamics loop

converged = false
nstep = 0
previous_barrier_height = Configuration.barrier_height

until ( converged or ($options[:limit_steps] and ( nstep > $options[:step_limit] ) ) )
	nstep += 1
	puts "\nStep  %3i  :: length  ::   dE eV  ::  angle  ::  gradient\n\n" % nstep
	Configuration.next_step
	converged = Configuration.converged
	puts Configuration.output
	puts "\nbarrier height =  %.4f eV\n       delta_E = %.4f eV" % [ (Configuration.barrier_height * $hartree_to_eV), ( ( Configuration.barrier_height - previous_barrier_height ) * $hartree_to_eV ) ]
	previous_barrier_height = Configuration.barrier_height
	write_to_output_file
end

puts "Finished"