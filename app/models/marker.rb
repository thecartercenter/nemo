class Marker

  def self.generate(color)
    # ensure there is a map-markers directory inside tmp
    tmp_path = File.join(Rails.root, "tmp/markers")
    Dir.mkdir(tmp_path) unless File.exists?(tmp_path)

    # build path to image we're going to generate
    file_path = File.join(tmp_path, "#{color}.png")

    # only generate if cached image doesn't exist already
    unless FileTest.exists?(file_path)

      # read the original marker image we're going to add color to
      orig_path = File.join(Rails.root, "public/images/markers/marker.png")
      orig = Magick::Image.read(orig_path)

      # color and write the image using floodfill
      colored = orig[0].color_floodfill(5, 5, "##{color}")
      colored.write(file_path)
    end

    # return the file path
    return file_path
  end

end
