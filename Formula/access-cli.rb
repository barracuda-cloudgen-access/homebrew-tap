class AccessCli < Formula
    desc "Cross-platform command line client for CloudGen Access Enterprise Console APIs"
    homepage "https://campus.barracuda.com/product/cloudgenaccess/doc/93201559/cloudgen-access-cli-client/" # rubocop:disable Style/StringLiterals
    version "0.15.2"

    if OS.mac?
      if Hardware::CPU.arm?
        url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.2/access-cli_macOS_arm64.tar.gz"
        sha256 "917fb199c4ffbf8a964250b6ebda8311f588bab39f6ebee466c2c13d68f9083b"
      else
        url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.2/access-cli_macOS_x86_64.tar.gz"
        sha256 "0678981d6dc4279b2f72cba897c9247cfb3aceec45f869fe40cec7a561755b47"
      end
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.2/access-cli_Linux_x86_64.tar.gz"
          sha256 "817401e56801a3e0b8674919f89f863b3e1dcb7c9ea05369550f2be91c1aa103"
        else
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.2/access-cli_Linux_i386.tar.gz"
          sha256 "49d04a824c706b059dc7fe9eba5df64a3a64c35a43adf9f26f68f3963179fcca"
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
