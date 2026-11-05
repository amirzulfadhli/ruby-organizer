require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"
require "rbconfig"

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
end