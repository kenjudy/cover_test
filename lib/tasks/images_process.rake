require_relative '../../config/initializers/app_constants'
require_relative '../../lib/image_processor'
require_relative '../../lib/move_to_s3'

namespace :images do
  
  task :process => :environment do |t, args|
   ImageProcessor.run
  end
end