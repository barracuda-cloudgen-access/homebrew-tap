class AccessCli < Formula
    desc "Cross-platform command line client for CloudGen Access Enterprise Console APIs"
    homepage "https://campus.barracuda.com/product/cloudgenaccess/doc/93201559/cloudgen-access-cli-client/"
    version "0.14.1"

    if OS.mac?
      url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.14.1/access-cli_0.14.1_macOS_x86_64.tar.gz"
      sha256 "2896661150705870c84cb129a6cc96b015b7f9959781e51af642faab1d20fd98"
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.14.1/access-cli_0.14.1_Linux_x86_64.tar.gz"
          sha256 "cf7d02820ae5b22609e9d6490a7ab611b023c9b1568fb6b398cd3d414fd97147"
        else
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.14.1/access-cli_0.14.1_Linux_i386.tar.gz"
          sha256 "22d8763b2e8dcbb59b1e171433b11c66234a1cbfb2e0215325ba2f6767f3e87a"
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
