# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
# about supported directives.


#= require jquery
#= require jquery_ujs
#= require twitter/bootstrap
#= require turbolinks
#= require_tree .

#= require masonry/jquery.masonry
#= require masonry/jquery.event-drag
#= require masonry/jquery.imagesloaded.min
#= require masonry/jquery.infinitescroll.min
#= require masonry/modernizr-transitions
#= require jquery.lazyload


$(window).load ->
  if $("#masonry-container").length
    $("#masonry-container").masonry
      "isFitWidth": true
      "itemSelector" : ".box > div"
      "columnWidth" : ".box > div"

class window.FileSizeCalculator
  constructor: () ->
    @original = @scrapeValues($(".original .filesize"))
    @new = @scrapeValues($(".new .filesize"))
    @count_original = @original.length
    @count_new = @original.length
    @total_original = @sumSizesForElement(@original)
    @total_new = @sumSizesForElement(@new)
    @difference = (@total_original - @total_new).toFixed(2)
    @mean_new = @arithmaticMean(@total_new, @count_new)
    @mean_original = @arithmaticMean(@total_original, @count_original)
    @stdev_new = @standardDeviation(@new, @mean_new)
    @stdev_original = @standardDeviation(@original, @mean_original)
    @max_new = @max(@new)
    @max_original = @max(@original)
    @min_new = @min(@new)
    @min_original = @min(@original)
    
  scrapeValues: (nodes) ->
    array = new Array
    nodes.each (index, node) ->
      array.push(parseFloat(node.innerText))
    array
    
  sumSizesForElement: (elements) ->
    total = 0
    total += filesize for filesize in elements
    total.toFixed(2)
    
  arithmaticMean: (sum, count) ->
    (sum / count).toFixed(2)
    
  standardDeviation: (elements, mean) ->
    sum = 0
    length = elements.length
    i = 0
    sum +=  Math.pow(filesize - mean, 2) for filesize in elements
    (Math.pow sum / length, 0.5).toFixed(2)
    
  max: (elements) ->
    Math.max.apply(Math, elements)
  
  min: (elements) ->
    Math.min.apply(Math, elements)
      
      