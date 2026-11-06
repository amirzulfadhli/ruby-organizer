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

  def run_undo
    Open3.capture3(RbConfig.ruby, @script, @folder)
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

    output, errors, status = run_undo

    assert status.success?, errors
    assert_equal 1, output.scan("WOULD RESTORE:").length
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

    output, errors, status = run_undo

    assert status.success?, errors
    assert_includes output, "SKIPPED: Original location occupied"
    assert_equal "original", File.read(source)
  end

  def test_missing_destination_is_skipped
    save_history([{
      "source" => File.join(@folder, "report.pdf"),
      "destination" => File.join(@folder, "Documents", "report.pdf")
    }])

    output, errors, status = run_undo

    assert status.success?, errors
    assert_includes output,  "SKIPPED: Destination missing"
  end
end
