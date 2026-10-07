require "fileutils"

folder = "test_files"

files = Dir.entries(folder)

categories = ["Images", "Documents", "Videos", "Archives", "Others"]

categories.each do |category|
  unless Dir.exist?(category)
    Dir.mkdir(category)
  end
end

files.each do |file|
  if File.file?(file)
    extension = File.extname(file)

    if [".jpg", ".png", ".gif"].include?(extension)
      category = "Images"
    elsif [".pdf", ".txt", ".docx"].include?(extension)
      category = "Documents"
    elsif [".mp4", ".mkv", ".mov"].include?(extension)
      category = "Videos"
    elsif [".zip", ".rar", ".7z"].include?(extension)
      category = "Archives"
    else
      category = "Others"
    end

    puts "#{file} → #{category}"

    FileUtils.mv(file, category)
  end
end