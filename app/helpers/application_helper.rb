module ApplicationHelper
  def isbn_from_filename(filename)
    filename.gsub(/cvr(\d{13,13})_.*/, '\1')
  end

  def quality_from_filename(filename)
    quality = filename.gsub(/.*_(\d\d\d)_lg\.jpg/, '\1')
    quality == filename ? nil : quality
  end
  def selectable_qualities
    [50,60,65,70,75,80,90,100]
  end
  
  def master_filesize
    @master_filesize ||= filesize(@master)
  end
  def filesize(filename)
    '%.2f' % (File.size("#{Rails.root}/app/assets/images/covers/#{filename}").to_f / 2**20 * 100)
  end
end
