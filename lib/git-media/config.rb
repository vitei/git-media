require 'git-media/helpers/git_ops'
require 'fileutils'

module GitMedia
  module Config

    extend Helpers::GitOps

    def self.run!(action)
      return uninstall_settings if action == :uninstall
      return install_settings if action == :install
      return print_status if action == :status
      return disable if action == :disable
      return enable if action == :enable
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

    def self.disable
      disabled_in_commit = get_git_config(disabled_in_commit_key)
      raise "git-media already disabled (in commit #{disabled_in_commit})" if disabled_in_commit != ""

      current_commit = `git rev-parse HEAD`
      set_git_config(disabled_in_commit_key, current_commit)
      set_git_config(filter_clean_key, filter_disabled_cmd)
      set_git_config(filter_smudge_key, filter_disabled_cmd)
    end

    def self.enable
      disabled_in_commit = get_git_config(disabled_in_commit_key)
      raise "git-media not currently disabled" if disabled_in_commit == ""

      locally_modified_files = `git status --porcelain`.split(/\n+/).select{|l| !(l =~ /^\?\?/)}
      if !locally_modified_files.empty?
        $stdout.puts "There are local modifications may be lost if you re-enable git-media now."
        $stdout.puts "Are you sure you want to proceed? (Type 'yes' in full to continue)"
        response = $stdin.gets.strip.downcase
        if response != "yes"
          exit 0
        end
      end

      unset_git_config(disabled_in_commit_key)
      set_git_config(filter_clean_key, filter_clean_cmd)
      set_git_config(filter_smudge_key, filter_smudge_cmd)

      current_commit = `git rev-parse HEAD`
      common_ancestor = `git merge-base #{disabled_in_commit} #{current_commit}`.strip
      my_diffs = get_diffs(common_ancestor, disabled_in_commit)
      their_diffs = get_diffs(common_ancestor, current_commit)
      diffs_since_disabled = my_diffs | their_diffs
      files_to_touch = diffs_since_disabled.map{|l| l.sub(/^./, "").strip}
      FileUtils.touch(files_to_touch)
      `git checkout -- .`
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
      "\"git-media filter-clean %f\""
    end

    def self.filter_smudge_cmd
      "\"git-media filter-smudge %f\""
    end

    def self.disabled_in_commit_key
      "git-media.disabledincommit"
    end

    def self.filter_disabled_cmd
      "cat"
    end

    def self.get_diffs(a, b)
      diffs = `git diff-tree --no-commit-id --name-status -r #{a} #{b}`
      diffs.split(/\n+/).select{|l| !(l =~ /^D/)}.map{|f| f.strip}
    end
  end
end