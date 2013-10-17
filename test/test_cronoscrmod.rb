require 'helper'

raise "Please specify $CRONOS_EXEC" unless ENV['CRONOS_EXEC']

class TestCronoscrmod < Test::Unit::TestCase
  def setup
		FileUtils.mkdir('test/jet') rescue 0
    @runner = CodeRunner.fetch_runner(Y: 'test/jet', C: 'cronos', X: ENV['CRONOS_EXEC'])
  end
  def teardown
    FileUtils.rm('test/jet/.code_runner_script_defaults.rb')
    #FileUtils.rm('test/jet/.CODE_RUNNER_TEMP_RUN_LIST_CACHE')
  end
  def test_basics
    assert_equal(@runner.run_class, CodeRunner::Cronos)
		@runner.print_out(0)
  end
	def test_matlab

		#require 'matlab'
		  
		##engine = Matlab::Engine.new(command = "#{ENV['MATLAB_BINDIR']}matlab  -nodesktop -nosplash")
	  #p ['output', CodeRunner::Cronos.rcp.engine.put_variable("x", 124.456)]
		#p ['output', CodeRunner::Cronos.rcp.engine.get_variable("x")]
	end
	def test_create
		CodeRunner.submit(Y: 'test/jet', p: '{aim: "test_cronos"}', T: true)
	end
end
