require 'fileutils'

module Go
    def self.compilation(options={}, &block)
        workspace = options[:workspace] || File.join(Dir.pwd, 'go')
        goversion = options[:goversion] || "1.3.3"
        context = CompilationContext.new(workspace, goversion)
        context.instance_eval &block
    end

    class CompilationContext
        def initialize(workspace, goversion)
            @workspace = workspace
            @goversion = goversion
        end

        def repository(repository, options={})
            path = options[:path]
            tag = options[:tag] || "master"
            destination = File.join(@workspace, 'src', path)
            if Dir.exists?(destination)
                Dir.chdir(destination) { system 'git', 'fetch', '--update-head-ok' }
            else
                system 'git', 'clone', repository, destination
            end
            Dir.chdir(destination) { system 'git', 'checkout', '-q', '-f', tag }
        end

        def package(name)
            system 'docker', 'run', '--rm', '-v', "#{@workspace}:/go", "golang:#{@goversion}", 'go', 'get', '-d', name
        end

        def build(package, options={})
            static = options[:static] || false
            go_command = ['docker', 'run', '--rm', '-v', "#{@workspace}:/go"]
            go_command << '-e' << 'CGO_ENABLED=0' if static
            go_command << "golang:#{@goversion}" << 'go' << 'install'
            go_command << '-a' << '--ldflags' << '-s -extldflags \"-static\"' if static
            go_command << package
            system *go_command
            system 'docker', 'run', '--rm', '-v', "#{@workspace}:/go", "golang:#{@goversion}", 'chown', '-R', "#{Process.uid}:#{Process.uid}", '/go'
        end

        def strip_binaries
            binaries.each do |binary|
                system 'strip', '--strip-debug', binary
            end
        end

        def copy_to target
            binaries.each do |binary|
                FileUtils.cp binary, target
            end
        end

        private

        def binaries
            Dir.glob(File.join(@workspace, 'bin', '*'))
        end
    end
end
