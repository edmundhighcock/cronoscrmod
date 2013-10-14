require 'helper'

class TestCronoscrmod < Test::Unit::TestCase
  def setup
		FileUtils.mkdir('test/jet') rescue 0
    @runner = CodeRunner.fetch_runner(Y: 'test/jet', C: 'cronos', X: '/dev/null')
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

		require 'matlab'
		  
		#engine = Matlab::Engine.new(command = "#{ENV['MATLAB_BINDIR']}matlab  -nodesktop -nosplash")
	  p ['output', CodeRunner::Cronos.rcp.engine.put_variable("x", 124.456)]
		p ['output', CodeRunner::Cronos.rcp.engine.get_variable("x")]
	end
end
