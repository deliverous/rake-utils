require 'fileutils'

module Go
    def self.compile(options={})
        goversion = options[:goversion] || "1.3.3"
        repository = options[:repository]
        tag = options[:tag] || "master"
        package = options[:package]
        workspace = options[:workspace]
        target = options[:target]
        static = options[:static] || false
        strip = options[:strip] || false
        path = File.join(workspace, 'src', package)
        if Dir.exists?(path)
            Dir.chdir(path) { system 'git', 'fetch', '--update-head-ok' }
        else
            system 'git', 'clone', repository, path
        end
        Dir.chdir(path) { system 'git', 'checkout', '-f', tag }
        go_command = ['docker', 'run', '--user', "#{Process.uid}", '--rm', '-v', "#{workspace}:/go"]
        go_command << '-e' << 'CGO_ENABLED=0' if static
        go_command << "golang:#{goversion}" << 'go' << 'get'
        go_command << '--ldflags' << '-s -extldflags \"-static\"' if static
        go_command << package
        system *go_command
        Dir.glob(File.join(workspace, 'bin', '*')).each do |binary|           
            system 'strip', '--strip-debug', binary  if strip
            FileUtils.cp binary, target
        end
    end
end
