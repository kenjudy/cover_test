module ApplicationHelper
  require 'exifr'
  
  def selectable_qualities
    SELECTABLE_QUALITIES
  end
  def image_filters
    IMAGE_FILTERS
  end
  
  def isbn_from_filename(filename)
    filename.gsub(/[\w_]+(\d{13,13})_.*/, '\1')
  end

  def quality_from_filename(filename)
    quality = filename.gsub(/.*_(\d\d\d)_lg\.jpg/, '\1')
    quality == filename ? nil : quality
  end
  
  def filesize(filename)
    '%.2f' % (File.size("#{Rails.root}#{COVER_IMAGE_DIR}/#{filename}").to_f / 1024)
  end
  
  def image_dimensions(filename, delim = "")
    begin
      exifr = EXIFR::JPEG.new("#{Rails.root}#{COVER_IMAGE_DIR}/#{filename}")
      "#{delim}#{exifr.width} x #{exifr.height}"
    rescue
    end
  end
  
  def filter_label(filter, nil_case = "None")
    filter && filter != "no_op" ? filter.humanize : nil_case
  end
  
  def is_current_filter(filter)
    filter == @filter || (filter == "no_op" && @filter.nil?)
  end
end
