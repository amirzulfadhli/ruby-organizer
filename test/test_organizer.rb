require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"
require "rbconfig"
require "json"

class TestOrganizer < Minitest::Test
  def setup
    @folder = Dir.mktmpdir("ruby-test-")
    @script = File.expand_path("../organizer.rb", __dir__)
  end

  def teardown
    FileUtils.remove_entry(@folder)
  end

  def run_organizer(*args)
    Open3.capture3(
      RbConfig.ruby, @script, @folder, *args
    )
  end

  def test_dry_run_does_not_move_files
    source = File.join(@folder, "photo.jpg")
    File.write(source, "test image")

    output, errors, status = run_organizer("--dry-run")

    assert status.success?, errors
    assert File.exist?(source)
    refute Dir.exist?(File.join(@folder, "Images"))
    assert_includes output, "photo.jpg -> Images"
  end

  def test_organizes_pdf
    source = File.join(@folder, "report.pdf")
    File.write(source, "test document")

    output, errors, status = run_organizer

    puts "OUTPUT: #{output}"
    puts "ERRORS: #{errors}"
    puts "EXIT STATUS: #{status.exitstatus}"

    puts "Folder: #{@folder}"
    puts "Files: #{Dir.glob(File.join(@folder, '**', '*'))}"

    assert status.success?, errors
    assert File.exist?(
      File.join(@folder, "Documents", "report.pdf")
    )
    refute File.exist?(source)
  end

  def test_skips_duplicate_filename
    images = File.join(@folder, "Images")
    Dir.mkdir(images)

    source = File.join(@folder, "photo.jpg")
    existing = File.join(images, "photo.jpg")

    File.write(source, "new image")
    File.write(existing, "original image")

    output, errors, status = run_organizer

    assert status.success?, errors
    assert_includes output, "SKIPPED: photo.jpg"
    assert_equal "new image", File.read(source)
    assert_equal "original image", File.read(existing)
  end

  def test_history_recors_successful_move
    File.write(File.join(@folder, "report.pdf"), "test")

    _, errors, status = run_organizer

    assert status.success?, errors

    history_file = File.join(@folder, ".ruby_history.json")
    assert File.exist?(history_file)

    history = JSON.parse(File.read(history_file))
    
    assert_equal 1, history.length
    assert_equal File.join(@folder, "report.pdf"),
                  history[0]["source"]
    assert_equal File.join(@folder, "Documents", "report.pdf"),
                  history[0]["destination"]
    assert history[0].key?("moved_at")
  end

  def test_history_preserved_across_runs
    File.write(File.join(@folder, "first.pdf"), "first")
    _, errors, status = run_organizer
    assert status.success?, errors

    File.write(File.join(@folder, "second.pdf"), "second")
    _, errors, status = run_organizer
    assert status.success?, errors

    history = JSON.parse(
      File.read(File.join(@folder, ".ruby_history.json"))
    )

    assert_equal 2, history.length
    assert_equal(
      ["first.pdf", "second.pdf"],
      history.map { |entry| File.basename(entry["source"])}
    )
  end
end