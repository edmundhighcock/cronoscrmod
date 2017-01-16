eputs "The Cronos CodeRunner module is written by Edmund Highcock, based on MatLab tools written by Jonathan Citrin" unless $has_put_startup_message_for_coderunner

#require 'matlab'
class CodeRunner
	class Cronos < Run
		# Where this file is
		@code_module_folder = folder = File.dirname(File.expand_path(__FILE__)) # i.e. the directory this file is in

		class EngineHandler
			def initialize(engine)
				@engine = engine
				@cronos_path_set = false
				@pathc
			end
			def start_cronos(path)
				return
				return if @cronos_path_set
				raise "cronos not found in #{path}" unless FileTest.exist?("#{path}/cronos.m")
				@engine.eval_string("addpath #{File.expand_path(path)};")
				@engine.eval_string("addpath #{File.expand_path(path)}/interface;")
				@engine.eval_string("addpath #{File.expand_path(path)}/op;")
				@engine.eval_string("cronos")
				@engine.eval_string("zuidirect")
				@cronos_path_set = true
			end

			def new_file
				@engine.eval_string("zuicreate")
				STDIN.gets
			end
		end

		def run_command
			"echo 'manual run'"
		end 

		module CodeRunner::InteractiveMethods
			def cronos(*args)
				if args.size > 0
					args.each do |com|
						begin
							CodeRunner::Cronos.rcp.engine_handler.cronos.puts(com)
						rescue Errno::EPIPE
							CodeRunner::Cronos.rcp.engine_handler.restart_cronos(@r.executable.sub(/cronos$/, ""))
							retry
						end
					end
				end
			end
		end



		class CronosHandler
			def initialize(runner)
				if runner and runner.executable
					start_cronos(runner.executable)
				end
			end
			attr_reader :cronos

			def start_cronos(path)
				return if @cronos_started
				raise "cronos not found in #{path}" unless FileTest.exist?("#{path}/cronos.m")
				@cronos = IO.popen("#{path}/cronos 3>&2 2>&1 1>&3 | grep -v 'Time Machine' 3>&2 2>&1 1>&3 ",  'w')
				@cronos.puts("addpath('#{CodeRunner::Cronos.rcp.code_module_folder}/matlab')")
				@cronos_started = true
			end
			def restart_cronos(path)
				@cronos_started = false
				start_cronos(path)
			end
			def new_file
				@cronos.puts("zuicreate")
			end
		end

		begin
	  	#@engine = Matlab::Engine.new("matlab -nodesktop -nosplash")
			#@engine_handler = EngineHandler.new(@engine)
			@engine_handler = CronosHandler.new((rcp.runner? ? rcp.runner : nil))
		#rescue => err
			#if err.to_s =~ /driver for matlab/
				#puts "Please make sure matlab is in your path"

				#raise
			#else
				#raise 
			#end
		end

		def set_cronos_path
			rcp.engine_handler.start_cronos(@runner.executable.sub(/cronos$/, ""))
		end

		




		################################################
		# Quantities that are read or determined by CodeRunner
		# after the simulation has ended
		###################################################

		@results = [
		]

		@variables = [
			:aim,
			:duplicate_id,

		]

		@code_long="Cronos Integrated Tokamak Modeller"

		@run_info=[:time, :is_a_restart, :restart_id, :restart_run_name, :completed_timesteps, :percent_complete]

		@uses_mpi = false

		@modlet_required = false
		
		@naming_pars = []

		#  Any subfolders of the main run folder
		@excluded_sub_folders = ["rapsauve_#{ENV['USER']}"]

		#  A hook which gets called when printing the standard run information to the screen using the status command.
		def print_out_line
			#p ['id', id, 'ctd', ctd]
			#p rcp.results.zip(rcp.results.map{|r| send(r)})
			name = @run_name
			name += " (res: #@restart_id)" if @restart_id
			name += " real_id: #@real_id" if @real_id
			beginning = sprintf("%2d:%d %-60s %1s:%2.1f(%s)",  @id, @job_no, name, @status.to_s[0,1],  @run_time.to_f / 60.0, @nprocs.to_s)
			if @status == :Incomplete and @completed_timesteps
				beginning += sprintf(" %d steps ", @completed_timesteps)
			elsif @percent_complete
 				beginning+=sprintf(" %3s%1s ", percent_complete, "%")
			end
			if ctd
				#beginning += sprintf("Q:%f, Pfusion:%f MW, Ti0:%f keV, Te0:%f keV, n0:%f x10^20", fusionQ, pfus, ti0, te0, ne0)
			end
			beginning += "  ---#{@comment}" if @comment
			beginning
		end


		#  This is a hook which gets called just before submitting a simulation. It sets up the folder and generates any necessary input files.
		def generate_input_file
			#FileUtils.touch("#@run_name.mat")
			#cronos.new_file
			#eputs "Make sure you save the file as #@run_name.mat... overwrite the existing empty place holder. When you have saved the file press enter."
			if @duplicate_id
				old = @runner.run_list[@duplicate_id]
				system "cp #{old.directory}/#{old.run_name}.mat #@directory/#@run_name.mat"
				load
			elsif @restart_id
				old = @runner.run_list[@restart_id]
				system "cp #{old.directory}/#{old.run_name}_resultat.mat #@directory/#@run_name.mat"
				load
			else
				sz = Terminal.terminal_size[1]
				eputs((str = "When you have created the file press enter. Don't save it (CodeRunner will automatically save it in the right place. You can edit parameters later as well. CodeRunner will not submit the file... submit it manually using a batch or interactive run."; ["-"*sz, str, "-"*sz]))
				cronos.puts("zuicreate")
				STDIN.gets
			end
			cronos.puts("param.gene.origine = '#@directory/#@run_name.mat'")
			cronos.puts("param.gene.file = '#@directory/#{@run_name}_resultat.mat'")
			cronos.puts("param.gene.rapsauve = '#@directory/#{@run_name}_resultat'")
			cronos.puts("param.edit.currentfile= '#@directory/#@run_name.mat'")
			cronos.puts("param.from.creation.com = '#@comment'")
			cronos.puts("zuisavedata('force')")
			#cronos.eval("zuicreate")
			refresh_gui
			
		end

		def refresh_gui
			cronos.puts(["[hfig,h] = zuiformhandle('direct');",
								   "if ishandle(hfig)
									 set(h.text_loadfile, 'string', param.gene.origine)
									 set(h.text_nom_machine, 'string', param.from.machine)
									 set(h.text_numchoc, 'string', sprintf('%d', param.from.shot.num))

									end"])	
		end

		def load
			cronos.puts("zuiload('#@directory/#@run_name.mat')")
			refresh_gui
		end

		def load_result
			cronos.puts("zuiload('#@directory/#{@run_name}_resultat.mat')")
			refresh_gui
		end

		def cronos
			set_cronos_path
			rcp.engine_handler.cronos
		end



		# Parameters which follow the Trinity executable, in this case just the input file.
		def parameter_string
		end

		def parameter_transition
		end


		@source_code_subfolders = []

		# This method, as its name suggests, is called whenever CodeRunner is asked to analyse a run directory. This happens if the run status is not :Complete, or if the user has specified recalc_all(-A on the command line) or reprocess_all (-a on the command line).
		#
		def process_directory_code_specific
			get_status
			#p ['fusionQ is ', fusionQ]
			#@percent_complete = completed_timesteps.to_f / ntstep.to_f * 100.0
		end

		def results_file_name
			"#{@run_name}_resultat.mat"
		end

		def get_status
			Dir.chdir(@directory) do
				if FileTest.exist? results_file_name
					@status = :Complete
					@percent_complete = 100.0
				elsif temps = Dir.entries.grep(/resultat_\d+/) and temps.size > 1
					@status = :Incomplete
					@completed_timesteps = temps.map{|f| f.scan(/resultat_(\d+)/)[0][0].to_i}.max
				else 
					@status = :Unknown
					@percent_complete = 0
				end
			end
		end

	end
end

