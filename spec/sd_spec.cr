require "spec"
require "../src/exceptions.cr"
require "../src/sd.cr"

# We are using a handmade config file for the purpose of testing.
dir = "./"
filename = "sd_spec.yml"
data = Data.load(dir, filename)

describe SD do
	describe "#resolve_path" do
		it "correctly identifies an existing local directory" do
			SD.resolve_path(data, "/var").should eq "/var"
		end

		it "correctly expands a non-conflicting shortcut" do
			SD.resolve_path(data, "short").should eq "/home"
		end

		it "correctly identifies a local directory" do
			src_path = Path["./src"].expand
			result_path = Path[SD.resolve_path(data, "src")].expand
			result_path.should eq src_path
		end

		it "throws an error when an invalid location is provided" do
			expect_raises(InvalidLocationException) do
				SD.resolve_path(data, "!@&*")
			end
		end
	end
end
