require "fileutils"

folder = "test_files"

files = Dir.entries(folder)

categories = ["Images", "Documents", "Videos", "Archives", "Others"]

categories.each do |category|
  category_path = File.join(folder, category)

  unless Dir.exist?(category_path)
    Dir.mkdir(category_path)
  end
end

files.each do |file|
  file_path = File.join(folder, file)

  if File.file?(file_path)
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

    destination = File.join(folder, category)

    puts "#{file} -> #{category}"

    FileUtils.mv(file_path, destination)
  end
end