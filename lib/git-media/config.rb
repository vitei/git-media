require 'git-media/helpers/git_ops'

module GitMedia
  module Config

    extend Helpers::GitOps

    def self.run!(action)
      return uninstall_settings if action == :uninstall
      return install_settings if action == :install
      return print_status if action == :status
      throw "Unknown action #{action}"
    end    

    def self.print_status
        if are_settings_installed? 
          puts("Filters are already installed")
        else
          puts("No filters found in configuration")
        end
    end

    def self.are_settings_installed?
      clean_filter_value = get_git_config(filter_clean_key)
      smudge_filter_value = get_git_config(filter_smudge_key)

      return !(clean_filter_value.empty? || smudge_filter_value.empty?) &&
            filter_clean_cmd.include?(clean_filter_value) &&
            filter_smudge_cmd.include?(smudge_filter_value)
    end

    def self.install_settings
      return print_status if are_settings_installed? 

      set_git_config(filter_clean_key, filter_clean_cmd)
      set_git_config(filter_smudge_key, filter_smudge_cmd)

      puts "Clean & smudge filters have been installed in the local repository configuration (.git/config)"
      puts "Remember to configure the transport for git-media to work correctly"
    end

    def self.uninstall_settings
      return print_status unless are_settings_installed? 

      git_config(filter_key, :remove_section)

      puts "Clean & smudge filters have been removed from the local repository git configuration"
    end

    private
    def self.filter_clean_key
      "filter.media.clean"
    end

    def self.filter_smudge_key
      "filter.media.smudge"
    end

    def self.filter_key
      "filter.media"
    end 

    def self.filter_clean_cmd
      "\"git-media filter-clean\""
    end

    def self.filter_smudge_cmd
      "\"git-media filter-smudge\""
    end
  end
end