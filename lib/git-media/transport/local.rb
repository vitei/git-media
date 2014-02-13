require 'git-media/transport'

# move large media to local bin

# git-media.transport local
# git-media.localpath /opt/media

module GitMedia
  module Transport
    class Local < Base

      def initialize(path)
        @path = path
      end

      def exist?(file)
        return File.exist?(file)
      end

      def get_file(sha, to_file)
        begin
			from_file = File.join(@path, sha)
			FileUtils.cp(from_file, to_file)
			return true
		rescue
			return false
		end
      end

      def put_file(sha, from_file)
        begin
			to_file = File.join(@path, sha)
			FileUtils.cp(from_file, to_file)
			return true
		rescue
			return false
		end
      end
      
    end
  end
end
