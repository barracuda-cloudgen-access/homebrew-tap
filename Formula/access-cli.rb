class AccessCli < Formula
    desc "Cross-platform command line client for CloudGen Access Enterprise Console APIs"
    homepage "https://campus.barracuda.com/product/cloudgenaccess/doc/93201559/cloudgen-access-cli-client/" # rubocop:disable Style/StringLiterals
    version "0.15.4"

    if OS.mac?
      if Hardware::CPU.arm?
        url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.4/access-cli_macOS_arm64.tar.gz"
        sha256 "f4a41054744ee864973060720c7b9e154cbb14ad7caeb4a3630371cbe2660187"
      else
        url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.4/access-cli_macOS_x86_64.tar.gz"
        sha256 "71107d2c7c8066ef2d7b4ee94569e5711f28c9cc5ec45d664fae6d118e74c941"
      end
    elsif OS.linux?
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.4/access-cli_Linux_x86_64.tar.gz"
          sha256 "d23783c7db9e444de16ae54bcc0501f5e987cf9e6ca6c4d6a0cd21e57aa51478"
        else
          url "https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v0.15.4/access-cli_Linux_i386.tar.gz"
          sha256 "99250bca398e61b9bdd8004b3476a8201b63faa3a5b3dc0999a738424609398e"
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
