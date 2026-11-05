require "fileutils"

folder = ARGV.find { |arg| arg != "--dry-run" }
dry_run = ARGV.include?("--dry-run")

if folder.nil?
  puts "Usage: ruby organizer.rb <folder>"
  exit
end

unless dry_run || Dir.exist?(folder)
  puts "Error: Folder '#{folder}' does not exist."
  exit
end

files = Dir.entries(folder)

puts "Scanning folder: #{File.expand_path(folder)}"
puts "Found entries: #{files.inspect}"

categories = ["Images", "Documents", "Videos", "Archives", "Others"]

unless dry_run
  categories.each do |category|
    category_path = File.join(folder, category)
    Dir.mkdir(category_path) unless Dir.exist?(category_path)
  end
end
 
files.each do |file|
  file_path = File.join(folder, file)

  if File.file?(file_path)
    extension = File.extname(file).downcase

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

    destination_folder = File.join(folder, category)
    destination = File.join(destination_folder, file)

    if File.exist?(destination)
      puts "SKIPPED: #{file} already exists in #{category}"
      next
    end

    puts "#{file} -> #{category}"

    puts "DEBUG: dry_run = #{dry_run}"


    unless dry_run
      FileUtils.mv(file_path, destination)
    end
  end
end