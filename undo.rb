require "json"

folder = ARGV.find { |arg| !arg.start_with?("--") }

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

  if File.basename(source) == ".ruby_history.json"
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

  puts "WOULD RESTORE: #{destination} -> #{source}"
end
