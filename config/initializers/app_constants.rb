module AppConstants

  COVER_IMAGE_DIR = "/public/images/covers"
  SELECTABLE_QUALITIES = [86,88,90,92,100]
  IMAGE_FILTERS = [:no_op, :despeckle, :auto_enhance, :enhance, :sharpen, :unsharp_mask]
  COVER_IMAGE_DROP_PATH = "#{Rails.root}/tmp/covers/"

  S3_CONFIG = YAML::load(File.open("#{Rails.root}/config/s3.yml"))
  S3_BUCKET = "sns-dev-test-2"
  S3_ACCESS_KEY_ID = S3_CONFIG["access_key_id"]
  S3_SECRET_ACCESS_KEY = S3_CONFIG["secret_access_key"]
  S3_COVER_IMAGES_PATH = "spikes/blitline-image-quality/"
  CDN_BOOK_URL = "http://d28hgpri8am2if.cloudfront.net/book_images/"

  BLITLINE_CONFIG = YAML::load(File.open("#{Rails.root}/config/blitline.yml"))
  BLITLINE_APP_ID = BLITLINE_CONFIG["application_id"]
end