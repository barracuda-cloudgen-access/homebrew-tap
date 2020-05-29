class FydeCli < Formula
    desc "Cross-platform command line client for Fyde Enterprise Console APIs"
    homepage "https://fyde.github.io/docs/fyde-cli/"
    version "0.9.0"
  
    if OS.mac?
      url "https://github.com/fyde/fyde-cli/releases/download/v0.9.0/fyde-cli_0.9.0_macOS_x86_64.tar.gz"
      sha256 "2830581c69a3bf1d44fd3913db524f437c05248187872d85d2d157d247a73530"
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/fyde/fyde-cli/releases/download/v0.9.0/fyde-cli_0.9.0_Linux_x86_64.tar.gz"
          sha256 "4fe1fa4706825713c86d6b0f8cced52f50b8b5708215934eb1c574ff7dc3da10"
        else
          url "https://github.com/fyde/fyde-cli/releases/download/v0.9.0/fyde-cli_0.9.0_Linux_i386.tar.gz"
          sha256 "bc2c054b0fa97dceffda42cdbbc003bb4d57a136488cc1266a57cb6b009992c7"
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
  
