require "spec"
require "../src/exceptions.cr"
require "../src/sd.cr"

# We are using a handmade config file for the purpose of testing.

# Just create a dummy variable for type safety
data = Data.from_yaml ""

# Create a sanitized data object for each test
Spec.before_each do
  data = Data.from_yaml <<-YAML
---
default: /home/directory
lock:
  locked: false
  location: /
shortcuts:
  /var: /mnt
  short: /home
history:
  enabled: false
  max_size: 10
  log: []
  index: 0
YAML
end

describe SD do
  describe "#resolve" do
    it "correctly identifies an existing local directory" do
      SD.resolve(data, "/var").should eq "/var"
    end

    it "correctly expands a non-conflicting shortcut" do
      SD.resolve(data, "short").should eq "/home"
    end

    it "correctly expands a conflicting shortcut when requested" do
      SD.resolve(data, "/var", shortcut: true).should eq "/mnt"
    end

    it "correctly identifies a local directory" do
      src_path = Path["./src"].expand
      result_path = Path[SD.resolve(data, "src")].expand
      result_path.should eq src_path
    end

    it "throws an error when an invalid location is provided" do
      expect_raises(InvalidLocationException) do
        SD.resolve(data, "!@&*")
      end
    end
  end

  describe "#set_default" do
    it "correctly sets the default path to a directory" do
      # This will raise an exception because our datafile cannot be
      # saved.
      expect_raises(TypeCastError) do
        SD.set_default(data, "/home", shortcut: false)
      end

      expected = Path["/home"].expand.to_s
      data.default.should eq expected
    end

    it "correctly sets the default path to a shortcut" do
      # This will raise an exception because our datafile cannot be
      # saved.
      expect_raises(TypeCastError) do
        SD.set_default(data, "short", shortcut: true)
      end

      expected = Path["/home"].expand.to_s
      data.default.should eq expected
    end

    it "correctly throws an error when an invalid location is used" do
      expect_raises(InvalidLocationException) do
        SD.set_default(data, "invalid")
      end
    end
  end

  describe "#get_default" do
    it "retrieves the default directory" do
      default = Path["/home/directory"].expand.to_s
      SD.get_default(data).should eq default
    end
  end

  describe "#navigate" do
    # TODO
    # I can't think of any way to test this!
  end

  describe "#lock_to" do

  end
end
