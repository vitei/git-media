
module GitMedia
  module FilterSmudge

    def self.run! (filename)
      #can_download = false # TODO: read this from config and implement

      if filename == nil
        filename = "(unknown)"
      end

      STDIN.binmode

      # read checksum size
      sha = STDIN.readpartial(40)

      STDOUT.binmode
      #STDERR.puts "smudge : "+filename

      if sha.match(/^[0-9a-fA-F]{40}$/)
      	#STDERR.puts("smudge "+media_buffer+", "+sha+"," +sha.chomp)

	  # this is a media file
        media_file = GitMedia.media_path(sha.chomp)
        if File.exists?(media_file)
          STDERR.puts('Recovering media ' + sha[0,8] + '.. ' + filename)
          File.open(media_file, 'rb') do |f|
            while data = f.read(4096) do
              print data
            end
          end
        else
          if GitMedia.filtersync?
            STDERR.puts('Downloading media ' + sha[0,8] + '.. ' + filename)
            @pull = GitMedia.get_pull_transport

            if @pull.pull(media_file, sha)
              File.open(media_file, 'rb') do |f|
                while data = f.read(4096) do
                  print data
                end
              end
            else
              STDERR.puts('Unable to fetch media ' + sha + ' : ' + filename)
              exit 1
            end
          else
            print sha+"\n"
          end
        end

      else
        STDERR.puts('Media pass thru: ' + filename)
        # if it is not a 40 character long hash, just output
        #STDERR.puts('Unknown git-media file format')
        print sha
        while data = STDIN.read(4096)
          print data
        end
        #STDERR.puts('Expected a stub file : '+sha)
        #exit(1)
      end
    end

  end
end
