module UploadToCdnStrategy
  include AppConstants
  
  class MoveToS3
    
    def process_file(key, local_file_path, cleanup = true)
      begin
        bucket = establish_connection_and_get_bucket
        upload_to_s3_with_public_read(key, local_file_path, bucket)
      ensure
        cleanup(local_file_path) if cleanup
      end
    end
    
    private
    
    def establish_connection_and_get_bucket
      RightAws::S3.new(AppConstants::S3_ACCESS_KEY_ID, AppConstants::S3_SECRET_ACCESS_KEY).bucket(AppConstants::S3_BUCKET)
    end
    
    def upload_to_s3_with_public_read(key, image_path, bucket)
      RightAws::S3::Key.create(bucket, key).put(open(image_path), 'public-read')
    end
    
    def cleanup(file_path)
      File.delete(file_path)
    end
    
  end
end