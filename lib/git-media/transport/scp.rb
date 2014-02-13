require 'git-media/transport'

require 'net/scp'




# move large media to remote server via SCP

# git-media.transport scp
# git-media.scpuser someuser
# git-media.scphost remoteserver.com
# git-media.scppath /opt/media

module GitMedia
  module Transport
    class Scp < Base

      def initialize(user, host, path, port)
	@user = user
	@host = host
        @path = path
	unless port === ""
	  @sshport = port
	end
	unless port === ""
	  @scpport = port
	end
      end

      def exist?(file)
		Net::SSH.start(@host, @user, {:port => @sshport}) do |ssh|
			return ssh.exec!('[ -f '+file+' ] && echo 1 || echo 0').chomp == "1"
		end
	   	return false
      end




      def get_file(sha, to_file)
        from_file = File.join(@path, sha)
		begin
			return Net::SCP.download!(@host,@user, from_file,to_file,{:port => @scpport})
		rescue
			return false
		end
      end

      def put_file(sha, from_file)
        to_file = File.join(@path, sha)
		begin
			Net::SCP.upload!(@host,@user, from_file,to_file,{:port => @scpport})
			return true
		rescue
			return false
		end
      end
      



    end
  end
end
