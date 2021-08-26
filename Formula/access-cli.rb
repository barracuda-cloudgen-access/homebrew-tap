class AccessCli < Formula
    desc "Cross-platform command line client for CloudGen Access Enterprise Console APIs"
    homepage "https://campus.barracuda.com/product/cloudgenaccess/doc/93201559/cloudgen-access-cli-client/"
    version "0.13.0"

    if OS.mac?
      url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.13.0/access-cli_0.13.0_macOS_x86_64.tar.gz"
      sha256 "a229e5146a65868d2d4d0d7150ba5de9e330095ac6d26d0d3a31616c095c7ad9"
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.13.0/access-cli_0.13.0_Linux_x86_64.tar.gz"
          sha256 "09ad4a9a65f64f860e2eddf39ba78295a7b764c8efc9085c10f098bd6365769b"
        else
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.13.0/access-cli_0.13.0_Linux_i386.tar.gz"
          sha256 "5577372ac0a98e91b8b9762ea2a1034478ddb52dd582e8becd584c23551c1dce"
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
