class AccessCli < Formula
    desc "Cross-platform command line client for CloudGen Access Enterprise Console APIs"
    homepage "https://campus.barracuda.com/product/cloudgenaccess/doc/93201559/cloudgen-access-cli-client/"
    version "0.14.2"

    if OS.mac?
      if Hardware::CPU.arm?
        url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.14.2/access-cli_0.14.2_macOS_arm64.tar.gz"
        sha256 "e021b3a364f40f905af44756ef08e4a00f84837ec7362bd0d0b62f23bbfd50c6"
      else
        url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.14.2/access-cli_0.14.2_macOS_x86_64.tar.gz"
        sha256 "6b6831ce2736dcafe2cf31d714197d9b08c79d6b3e52eca0f79cdb029cdf0ecb"
      end
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.14.2/access-cli_0.14.2_Linux_x86_64.tar.gz"
          sha256 "618d6d65e75200ea2c32004c5258fe256389f4c4f56e01df2003c6b33164c826"
        else
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.14.2/access-cli_0.14.2_Linux_i386.tar.gz"
          sha256 "bdd727512b01e753ec7c0abc50d5d74e713c1ff20d724b4fc5923d02c6bf01e6"
        end
      end
    end

    head do
      url "https://github.com/barracuda-cloudgen-access/access-cli.git",
          :branch => "develop"

      depends_on "go" => :build

      resource "go-swagger" do
        url "https://github.com/go-swagger/go-swagger.git",
            :tag => "v0.27.0"
      end
    end

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
          "-o", "access-cli",
          "-ldflags", ldflags.join(" ")
      end

      bin.install "access-cli"

      # Install bash completion
      output = Utils.popen_read("#{bin}/access-cli completion bash")
      (bash_completion/"access-cli").write output

      # Install zsh completion
      output = Utils.popen_read("#{bin}/access-cli completion zsh")
      (zsh_completion/"_access-cli").write output

      if build.head?
        # Clean up build path (go mod creates files that Homebrew won't delete)
        system "go", "clean", "-modcache"
      end
    end

    test do
      version_output = shell_output("#{bin}/access-cli version")
      assert_match /Version v?#{Regexp.escape(version)}/, version_output
      refute_match /uncommitted changes/, version_output
    end
  end
