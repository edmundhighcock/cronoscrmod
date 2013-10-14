cronoscrmod
===========

A module to allow CodeRunner to run the integrated tokamak modelling suite Cronos


cronoscrmod requires matlab-ruby, but for technical reasons, you must install this yourself manually. 

Try:

`gem install matlab-ruby`

If this fails, see the notes below.


Notes
-----


Instructions for Mac OS X

You need to install matlab-ruby for cronoscrmod, but `gem install matlab-ruby` does not in general work. It is recommended that you install it yourself like this:


`git clone git@github.com:edmundhighcock/matlab-ruby.git`

`cd matlab-ruby`

`ruby setup.rb config -- --with-matlab-include=/Applications/MATLAB_R2012a.app/extern/include/ --with-matlab-lib=/Applications/MATLAB_R2012a.app/bin/maci64/`

`ruby setup.rb setup`

`sudo ruby setup.rb install`

You also need to make sure the Matlab libraries are in the linker path:

Add these lines to your login script:

`export PATH=$PATH:/Applications/MATLAB_R2012a.app/bin/`

`export DYLD_LIBRARY_PATH=/Applications/MATLAB_R2012a.app/bin/maci64:$DYLD_LIBRARY_PATHo`

