require 'optparse'

def set_options

	options = {}

	optparse = OptionParser.new do |opts|

		options[:climbing] = false
		opts.on( '-c', '--climbing-on', 'Use climbing NEB algorithm' ) do
			options[:climbing] = true # see http://theory.cm.utexas.edu/vtsttools/neb/
		end

		options[:output] = 'neb.out'
		opts.on( '-o', '--output FILE', "Write output to file FILE (default #{options[:output]})" ) do |f|
			options[:output] = f
		end

		options[:input] = 'neb.inpt'
		opts.on( '-i', '--input FILE', "Read input from file FILE (default #{options[:input]})" ) do |f|
			options[:input] = f
		end

		options[:diagnostic] = false
		opts.on( '-d', '--diagnostic-on [IMAGE_NUMBER]', 'Report diagnostic information IMAGE_NUMBER (default 1)' ) do |i|
			options[:diagnostic] = true
			options[:diagnostic_image] = i.to_i || 1
		end

		options[:parallel] = false
		opts.on( '-p', '--parallel VALUE', 'Parallelise across NPROCS processes' ) do |p|
			options[:parallel] = true
			options[:nprocs] = p.to_i
		end

		options[:convergence] = 5.0e-4
		opts.on( '-v', '--convergence VALUE', 'Set forces convergence' ) do |c|
			options[:convergence] = c.to_f
		end

		options[:timestep] = 1.0
		opts.on( '-t', '--timestep VALUE', "Set timestep for Velocity Verlet integration (default #{options[:timestep]})" ) do |t|
			options[:timestep] = t.to_f
		end

		options[:spring_constants] = 0.05
		opts.on( '-s', '--spring-constant VALUE', "Set spring constant for springs between images (default #{options[:spring_constants]})" ) do |s|
			options[:spring_constants] = s.to_f
		end

		options[:new_calculation] = false
		opts.on( '-n', '--new-calculation', "Start a new calculation. This deletes all previous \'image\' directories" ) do
			options[:new_calculation] = true
		end

		options[:restart_calculation] = false
		opts.on( '-r', '--resart-calculation', "Restart a calculation using configurations in \'image\' directories (NOT IMPLEMENTED)" ) do
			options[:resart_calculation] = true
		end

		options[:limit_steps] = false
		options[:step_limit] = 500
		opts.on( '-m', '--maximum-number-of-steps VALUE', "Maximum number of relaxation steps (default: unlimited)" ) do |s|
			options[:limit_steps] = true
			options[:step_limit] = s.to_i
		end

		opts.on( '-h', '--help', 'Display this information' ) do
			puts opts
			exit
		end

	end

	optparse.parse!

	return options

end