module GitMedia
  module Helpers
    module GitOps

      def git_config(key, action, value=nil)
        action = "--#{action.to_s.gsub('_', '-')}" unless action.nil?

        cmd = "git config --local #{action} #{key} #{value}"
        `#{cmd}`
      end

      def get_git_config(key)
        git_config(key, :get).strip
      end

      def set_git_config(key, value)
        git_config(key, nil, value)
      end

      def unset_git_config(key)
        git_config(key, :unset, nil)
      end
    end
  end
end