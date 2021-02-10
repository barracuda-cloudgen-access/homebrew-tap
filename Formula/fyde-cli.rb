class FydeCli < Formula
    desc "Cross-platform command line client for Fyde Enterprise Console APIs"
    homepage "https://fyde.github.io/docs/fyde-cli/"
    version "0.11.0"

    if OS.mac?
      url "https://github.com/fyde/fyde-cli/releases/download/v0.11.0/fyde-cli_0.11.0_macOS_x86_64.tar.gz"
      sha256 "0a990f3e1b5688e966da886131c93fb6b3e46d2cb685a929d2f1c261f642abda"
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/fyde/fyde-cli/releases/download/v0.11.0/fyde-cli_0.11.0_Linux_x86_64.tar.gz"
          sha256 "05a4bed3b1ecfc897237e7a102cead7e9662775a48ad02468b8772a99abc13b4"
        else
          url "https://github.com/fyde/fyde-cli/releases/download/v0.11.0/fyde-cli_0.11.0_Linux_i386.tar.gz"
          sha256 "e0ce9e5b90ebb2c8d3cc79cecaf1609576ec5377ce3f228d24e0c8b8221dfd48"
        end
      end
    end

    head do
      url "https://github.com/fyde/fyde-cli.git",
          :branch => "develop"

      depends_on "go" => :build

      resource "go-swagger" do
        url "https://github.com/go-swagger/go-swagger.git",
            :tag => "v0.21.0"
      end
    end

    bottle :unneeded

    def install
      if build.head?
        home_bindir = Pathname.new(ENV["HOME"])/"bin"
        ENV.prepend_create_path "PATH", home_bindir

        resource("go-swagger").stage do
          system "go", "build", "-o", home_bindir/"swagger", "./cmd/swagger"
        end

        # Generate code
        system "swagger", "generate", "client", "-f", "swagger.yml"
        system "go", "mod", "tidy"
        system "go", "generate", "./..."

        ldflags = [
          "-s", "-w",
          "-X", "main.GitCommit=#{version.commit}",
          "-X", "main.BuildDate=#{Time.now.utc.iso8601}",
          "-X", "main.Version=#{version}",
          "-X", "main.GitState=clean"
        ]

        # Perform build
        system "go", "build",
          "-o", "fyde-cli",
          "-ldflags", ldflags.join(" ")
      end

      bin.install "fyde-cli"

      # Install bash completion
      output = Utils.popen_read("#{bin}/fyde-cli completion bash")
      (bash_completion/"fyde-cli").write output

      # Install zsh completion
      output = Utils.popen_read("#{bin}/fyde-cli completion zsh")
      (zsh_completion/"_fyde-cli").write output

      if build.head?
        # Clean up build path (go mod creates files that Homebrew won't delete)
        system "go", "clean", "-modcache"
      end
    end

    test do
      version_output = shell_output("#{bin}/fyde-cli version")
      assert_match /Version v?#{Regexp.escape(version)}/, version_output
      refute_match /uncommitted changes/, version_output
    end
  end
