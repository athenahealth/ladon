# Top level namespace for all Ladon framework internals.
module Ladon
end

require 'ladon/_version' # versioning info

# require all of the common stuff

require 'ladon/common/flags'
require 'ladon/common/errors'

# require data stuff
require 'ladon/common/data/config'
require 'ladon/common/data/result'
require 'ladon/common/data/result/junit'

# require assertion stuff
require 'ladon/common/assertions/assertions'

# require timing stuff
require 'ladon/common/timing/timer'
require 'ladon/common/timing/time_entry'

# require logging stuff
require 'ladon/common/logging/level'
require 'ladon/common/logging/logger'
require 'ladon/common/logging/log_entry'

# require bundle
require 'ladon/common/bundle'
