class CoversController < ApplicationController

  def index
    @files = Dir.entries("#{Rails.root}/app/assets/images/covers").keep_if{ |file| file =~ /\d{13,13}_lg\.jpg/ }
  end


  def show
    @master = filename_from_isbn(params['isbn13'])
    @files = Dir.entries("#{Rails.root}/app/assets/images/covers").keep_if{ |file| file =~ /#{params['isbn13']}_\d\d\d_lg\.jpg/ }
  end
  
  def quality
    @quality = format('%03d', params["quality"])
    masters = Dir.entries("#{Rails.root}/app/assets/images/covers").keep_if{ |file| file =~ /\d{13,13}_lg\.jpg$/ }
    comparisons = Dir.entries("#{Rails.root}/app/assets/images/covers").keep_if{ |file| file =~ /\d{13,13}_#{@quality}_lg\.jpg/ }
    @files = {}
    masters.each do |master| 
      comparison = filename_from_isbn(isbn_from_filename(master), @quality)
      @files[master] = comparison if comparisons.include?(comparison)
    end
  end
end