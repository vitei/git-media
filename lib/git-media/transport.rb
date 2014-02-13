module GitMedia
  module Transport
    class Base

      def pull(final_file, sha)
        to_file = GitMedia.media_path(sha)
        return get_file(sha, to_file)
      end

      def push(sha)
        from_file = GitMedia.media_path(sha)
        return put_file(sha, from_file)
      end


      ## OVERWRITE ##
      
      def exist?(file)
        false
      end

      def get_file(sha, to_file)
        false
      end

      def put_file(sha, to_file)
        false
      end
      
      def get_unpushed(files)
        files.select do |f|
          !exist?(File.join(@path, f))
        end
      end
      
      def needs_push(sha)
        return !exist?(File.join(@path, sha))
      end

      
    end
  end
end
