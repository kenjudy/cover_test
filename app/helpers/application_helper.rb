module ApplicationHelper
  require 'exifr'
  
  def cover_image_dir
    AppConstants::COVER_IMAGE_DIR
  end
  
  def selectable_qualities
    AppConstants::SELECTABLE_QUALITIES
  end
  def image_filters
    AppConstants::IMAGE_FILTERS
  end
  
  def isbn_from_filename(filename)
    filename.gsub(/[\w_]+(\d{13,13})_.*/, '\1')
  end
  
  def filter_from_filename(filename)
    filter = filename.gsub(/.*\d{13,13}_([\w_]+)_\d{3}.*$/, '\1').humanize
    filter.include?(".jpg") ? "" : filter
  end

  def quality_from_filename(filename)
    quality = filename.gsub(/.*_(\d\d\d)_lg\.jpg/, '\1')
    quality == filename ? nil : quality
  end
  
  def filesize(filename)
    '%.2f' % (File.size("#{Rails.root}#{cover_image_dir}/#{filename}").to_f / 1024)
  end
  
  def image_dimensions(filename)
    begin
      exifr = EXIFR::JPEG.new("#{Rails.root}#{cover_image_dir}/#{filename}")
      { width: exifr.width, height: exifr.height}
    rescue
      {}
    end
  end
  
  def image_dimensions_style(dim)
    return if dim == {}
    "max-width: #{dim[:width]}px;width: #{dim[:width]}px; height: #{dim[:height]}px;"
  end
  
  def filter_label(filter, nil_case = "None")
    filter && filter != :no_op ? filter.to_s.humanize : nil_case
  end
  
  def is_current_filter(filter)
    filter == @filter || (filter == :no_op && @filter.nil?)
  end
end
