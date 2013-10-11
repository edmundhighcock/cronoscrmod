class CodeRunner
	class Cronos < Run
		# Where this file is
		@code_module_folder = folder = File.dirname(File.expand_path(__FILE__)) # i.e. the directory this file is in


		################################################
		# Quantities that are read or determined by CodeRunner
		# after the simulation has ended
		###################################################

		@results = [
		]

		@variables = [
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
			beginning = sprintf("%2d:%d %-60s %1s:%2.1f(%s) %3s%1s",  @id, @job_no, name, @status.to_s[0,1],  @run_time.to_f / 60.0, @nprocs.to_s, percent_complete, "%")
			if ctd
				beginning += sprintf("Q:%f, Pfusion:%f MW, Ti0:%f keV, Te0:%f keV, n0:%f x10^20", fusionQ, pfus, ti0, te0, ne0)
			end
			beginning += "  ---#{@comment}" if @comment
			beginning
		end


		#  This is a hook which gets called just before submitting a simulation. It sets up the folder and generates any necessary input files.
		def generate_input_file
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

		def get_status
		end

	end
end

