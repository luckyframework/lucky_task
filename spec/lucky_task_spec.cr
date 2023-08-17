require "./spec_helper"

describe LuckyTask do
  it "has version in sync with shard.yml" do
    content = File.open("shard.yml") do |file|
      file.gets_to_end
    end

    version = /version\:(.*?)\n/.match(content).as(Regex::MatchData)[1].strip
    version.should eq LuckyTask::VERSION
  end
end
