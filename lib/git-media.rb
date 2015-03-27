require 'trollop'
require 'fileutils'

module GitMedia

  def self.get_media_buffer
    @@git_dir ||= `git rev-parse --git-dir`.chomp
    media_buffer = File.join(@@git_dir, 'media/objects')
    FileUtils.mkdir_p(media_buffer) if !File.exist?(media_buffer)
    return media_buffer
  end

  def self.media_path(sha)
    buf = self.get_media_buffer
    File.join(buf, sha)
  end

  def self.get_push_transport
    self.get_transport
  end

  def self.filtersync?
    if `git config git-media.filtersync`.chomp === "false"
      return false
    end
    return true
  end

  def self.get_transport
    transport = `git config git-media.transport`.chomp

    case transport
    when ""
      raise "git-media.transport not set"
    when "scp"
      user = `git config git-media.scpuser`.chomp
      host = `git config git-media.scphost`.chomp
      path = `git config git-media.scppath`.chomp
      port = `git config git-media.scpport`.chomp
      if user === ""
        raise "git-media.scpuser not set for scp transport"
      end
      if host === ""
        raise "git-media.scphost not set for scp transport"
      end
      if path === ""
        raise "git-media.scppath not set for scp transport"
      end
      require 'git-media/transport/scp'
      GitMedia::Transport::Scp.new(user, host, path, port)

    when "local"
      path = `git config git-media.localpath`.chomp
      if path === ""
        raise "git-media.localpath not set for local transport"
      end
      require 'git-media/transport/local'
      GitMedia::Transport::Local.new(path)
    when "s3"
      bucket = `git config git-media.s3bucket`.chomp
      key = `git config git-media.s3key`.chomp
      secret = `git config git-media.s3secret`.chomp
      if bucket === ""
        raise "git-media.s3bucket not set for s3 transport"
      end
      if key === ""
        raise "git-media.s3key not set for s3 transport"
      end
      if secret === ""
        raise "git-media.s3secret not set for s3 transport"
      end
      require 'git-media/transport/s3'
      GitMedia::Transport::S3.new(bucket, key, secret)
    when "atmos"
      require 'git-media/transport/atmos_client'
      endpoint = `git config git-media.endpoint`.chomp
      uid = `git config git-media.uid`.chomp
      secret = `git config git-media.secret`.chomp
      tag = `git config git-media.tag`.chomp

      if endpoint == ""
        raise "git-media.endpoint not set for atmos transport"
      end

      if uid == ""
        raise "git-media.uid not set for atmos transport"
      end

      if secret == ""
        raise "git-media.secret not set for atmos transport"
      end
      GitMedia::Transport::AtmosClient.new(endpoint, uid, secret, tag)
    when "drive"
      require 'git-media/transport/drive'
      email = `git config git-media.email`.chomp
      asp = `git config git-media.asp`.chomp
      collection = `git config git-media.collection`.chomp
      if email == ""
        raise "git-media.email not set for drive transport"
      end
      if asp == ""
        raise "git-media.asp (application specific password) not set for drive transport"
      end
      if collection == ""
        raise "git-media.collection not set for drive transport"
      end
      GitMedia::Transport::Drive.new(email, asp, collection)
    when "hashstash"
      require 'git-media/transport/hashstash'
      host = `git config git-media.host`
      port = `git config git-media.port`
      origin = `git config remote.origin.url`

      GitMedia::Transport::HashStash.new(host,port,origin)
    else
      raise "Invalid transport #{transport}"
    end
  end

  def self.get_pull_transport
    self.get_transport
  end

  module Application
    def self.run!

      cmd = ARGV.shift # get the subcommand

      case cmd
        when "filter-clean" # parse delete options
          require 'git-media/filter-clean'
          GitMedia::FilterClean.run! ARGV.shift
        when "filter-smudge"
          require 'git-media/filter-smudge'
          GitMedia::FilterSmudge.run! ARGV.shift
        when "clear" # parse delete options
          require 'git-media/clear'
          GitMedia::Clear.run!
        when "sync"
          require 'git-media/sync'
          GitMedia::Sync.run!
	when "check"
	  require 'git-media/check'
	  GitMedia::Check.run!
        when "download"
          require 'git-media/sync'
          GitMedia::Sync.run! :download_only => true
        when 'status'
          require 'git-media/status'
          require 'git-media/config'
          Trollop::options do
            opt :force, "Force status"
          end
          GitMedia::Status.run!
          GitMedia::Config.run!(:status)
		    when 'list'
		      require 'git-media/list'
		      GitMedia::List.run!
        when 'install'
          require 'git-media/config'
          GitMedia::Config.run!(:install)
        when 'uninstall'
          require 'git-media/config'
          GitMedia::Config.run!(:uninstall)
        else
	       print <<EOF
usage: git media sync|download|status|list|clear|check
  
  sync      Sync files with remote server
  download  Download files that are missing; don't upload any files
  status    Show files that are waiting to be uploaded and file size
  list      List local cache and corresponding media file
  clear     Upload and delete the local cache of media files
  check     Check local media cache and download any corrupt files
  install   Set up the attributes filter settings in git config  
  uninstall Removes the attributes filter settings in git config  
EOF
      end
    end
  end
end
