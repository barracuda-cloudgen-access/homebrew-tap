class FydeCli < Formula
    desc "Cross-platform command line client for Fyde Enterprise Console APIs"
    homepage "https://fyde.github.io/docs/fyde-cli/"
    version "0.8.3"
  
    if OS.mac?
      url "https://github.com/fyde/fyde-cli/releases/download/v0.8.3/fyde-cli_0.8.3_macOS_x86_64.tar.gz"
      sha256 "9f22fd6045fcad84d8cd0cf1f30b060ead7ca0c6bfd79ca386115c7e1476e71a"
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/fyde/fyde-cli/releases/download/v0.8.3/fyde-cli_0.8.3_Linux_x86_64.tar.gz"
          sha256 "d2a866b1c8131e634ff2001659893a0ab93b28fb96f0450026816279902e23f2"
        else
          url "https://github.com/fyde/fyde-cli/releases/download/v0.8.3/fyde-cli_0.8.3_Linux_i386.tar.gz"
          sha256 "75e037cc96d8d4145385d4791d87f387baca68819deada6e5d10b3ada0b16c8f"
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
  
