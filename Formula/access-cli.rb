class AccessCli < Formula
    desc "Cross-platform command line client for CloudGen Access Enterprise Console APIs"
    homepage "https://campus.barracuda.com/product/cloudgenaccess/doc/93201559/cloudgen-access-cli-client/" # rubocop:disable Style/StringLiterals
    version "0.15.0"

    if OS.mac?
      if Hardware::CPU.arm?
        url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.0/access-cli_0.15.0_macOS_arm64.tar.gz"
        sha256 "e94d43040c3dec61a6f4aa6c9e00163bec628a643fcd4f5aa39781a6526067c9"
      else
        url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.0/access-cli_0.15.0_macOS_x86_64.tar.gz"
        sha256 "4d7fee93e04019b9480f2ffe3795fed859e48a2ce7437f851c8765ff7ac5e63a"
      end
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.0/access-cli_0.15.0_Linux_x86_64.tar.gz"
          sha256 "6d8c587101fda880d6f44373b59c95b371d9ad074fbee856667ac4e20660adb9"
        else
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.0/access-cli_0.15.0_Linux_i386.tar.gz"
          sha256 "c71129f9865613e28684cca008e8c097a04efda98faeecbc8e9ef56ec6a3c19b"
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
