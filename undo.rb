require "json"
require "FileUtils"

folder = ARGV.find { |arg| !["--dry-run", "--apply"].include?(arg)}
dry_run = ARGV.include?("--dry-run")
apply = ARGV.include?("--apply")

puts "Folder: #{folder.inspect}"
puts "Apply mode: #{apply}"

if folder.nil? || !Dir.exist?(folder)
  warn "usage: ruby undo.rb <folder>"
  exit 1 
end

history_file = File.join(folder, ".ruby_history.json")

unless File.exist?(history_file)
  warn "No history file found"
  exit 1
end

begin
  history = JSON.parse(File.read(history_file))
rescue JSON::ParserError
  warn "History file is invalid"
  exit 1
end

unless history.is_a?(Array)
  warn "Invalid history format"
  exit 1
end

root = File.expand_path(folder)
seen = {}

history.reverse_each do |entry|
  unless entry.is_a?(Hash) &&
      entry["source"].is_a?(String) &&
      entry["destination"].is_a?(String)
    puts "SKIPPED: Invalid history entry"
    next
  end

  source = File.expand_path(entry["source"])
  destination = File.expand_path(entry["destination"])

  if File.basename(source) == ".ruby_history.json" ||
     File.basename(destination) == ".ruby_history.json"
    puts "SKIPPED: Ruby history file"
    next
  end

  if seen[source] || seen[destination]
    puts "SKIPPED: Duplicate history path"
    next
  end

  seen[source] = true
  seen[destination] = true

  prefix = root + File::SEPARATOR

  unless source.start_with?(prefix) &&
        destination.start_with?(prefix)
    puts "SKIPPED: Path outside selected folder"
    next
  end

  unless File.exist?(destination)
    puts "SKIPPED: Destination missing: #{destination}"
    next
  end

  if File.exist?(source)
    puts "SKIPPED: Original location occupied: #{source}"
    next
  end

  if apply
    parent = File.dirname(source)

    unless Dir.exist?(parent)
      puts "SKIPPED: Original parent directory missing"
      next
    end

    resolved_root = File.realpath(root)
    resolved_parent = File.realpath(parent)

    safe_parent = resolved_parent == resolved_root ||
      resolved_parent.start_with?(resolved_root + File::SEPARATOR)

    resolved_destination = File.realpath(destination)

    safe_destination = resolved_destination.start_with?(
      resolved_root  + File::SEPARATOR
    )
  
    unless safe_parent && safe_destination
      puts "SKIPPED: Unsafe file path"
      next
    end

    puts "Safe destination: #{safe_destination}"
    puts "Safe parent directory: #{safe_parent}"

    if Dir.exist? (parent)
      puts "Parent directory exist"
    else
      puts "Parent directory needs to be created "
    end

    if File.symlink?(source) || File.symlink?(destination) || !File.file?(destination)
      puts "SKIPPED: Unsupported file path"
      next
    end

    FileUtils.mv(destination, source)
    puts "RESTORED: #{source}"

  else
    puts "WOULD RESTORE: #{source}"
  end
end
