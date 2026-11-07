require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "json"
require "open3"
require "rbconfig"

class TestUndo < Minitest::Test
  def setup
    @folder = Dir.mktmpdir("ruby-undo-")
    @script = File.expand_path("../undo.rb", __dir__)
  end

  def teardown
    FileUtils.remove_entry(@folder) if  @folder && Dir.exist?(@folder)
  end

  def run_undo(apply: false)
    args = [RbConfig.ruby, @script, @folder]
    args << "--apply" if apply

    Open3.capture3(*args)
  end

  def save_history(entries)
    File.write(
      File.join(@folder, ".ruby_history.json"),
      JSON.pretty_generate(entries)
    )
  end

  def test_valid_undo_preview
    destination = File.join(@folder, "Documents", "report.pdf")
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, "test")

    save_history([{
      "source" => File.join(@folder, "report.pdf"),
      "destination" => destination
    }])

    output, errors, status = run_undo

    assert status.success?, errors
    assert_includes output, "WOULD RESTORE"
    assert File.exist?(destination)
  end

  def test_duplicates_history_is_skipped
    destination = File.join(@folder, "Documents", "report.pdf")
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, "test")

    entry = {
      "source" => File.join(@folder, "report.pdf"),
      "destination" => destination
    }

    save_history([entry, entry])

    output, errors, status = run_undo(apply: true)

    assert status.success?, errors
    assert_equal 1, output.scan("RESTORED:").length
    assert_includes output, "SKIPPED: Duplicate history path"
  end

  def test_existing_original_is_not_overwritten
    source = File.join(@folder, "report.pdf")
    destination = File.join(@folder, "Documents", "report.pdf")

    FileUtils.mkdir_p(File.dirname(destination))
    File.write(source, "original")
    File.write(destination, "organized")

    save_history([{
      "source" => source,
      "destination" => destination
    }])

    output, errors, status = run_undo(apply: true)

    assert status.success?, errors
    assert_includes output, "SKIPPED: Original location occupied"
    assert_equal "original", File.read(source)
    assert_equal "organized", File.read(destination)
  end

  def test_missing_destination_is_skipped
    source = File.join(@folder, "report.pdf")
    destination = File.join(@folder, "Documents", "report.pdf")

    save_history([{
      "source" => source,
      "destination" => destination
    }])

    output, errors, status = run_undo(apply: true)

    assert status.success?, errors
    assert_includes output,  "SKIPPED: Destination missing"
    refute File.exist?(source)
    refute File.exist?(destination)
  end

  def test_missing_parent_directory_is_skipped
    source = File.join(@folder, "Missing", "report.pdf")
    destination = File.join(@folder, "Documents", "report.pdf")

    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, "test")

    save_history([{
      "source" => source,
      "destination" => destination
    }])

    output, errors, status = run_undo(apply: true)

    assert status.success?, errors
    assert_includes output, "SKIPPED: Original parent directory missing"

    puts "Source exist: #{File.exist?(source)}"
    puts "Destincation exist: #{File.exist?(destination)}"
    puts "Destination path: #{destination}"
    
    assert File.exist?(destination)
    refute File.exist?(source)
  end

  def test_apply_restores_file
    source = File.join(@folder, "report.pdf")
    destination = File.join(@folder, "Documents", "report.pdf")

    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, "test content")

    save_history([{
      "source" => source,
      "destination" => destination
    }])

    output, errors, status = run_undo(apply: true)

    assert status.success?, errors
    assert File.exist?(source)
    refute File.exist?(destination)
    assert_equal "test content", File.read(source)
  end

  def test_outside_source_is_skipped
    source = File.join(File.dirname(@folder), "outside.pdf")
    destination = File.join(@folder, "Documents", "report.pdf")

    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, "test")

    save_history([{
      "source" => source,
      "destination" => destination
    }])

    output, errors, status = run_undo(apply: true)

    assert status.success?, errors
    assert_includes output, "SKIPPED: Path outside selected folder"
    assert File.exist?(destination)
    refute File.exist?(source)
  end
end
