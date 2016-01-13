class PcapDnsproxy < Formula
  desc "Powerful DNS proxy designed to anti DNS spoofing"
  homepage "https://github.com/chengr28/Pcap_DNSProxy"
  url "https://github.com/chengr28/Pcap_DNSProxy/archive/v0.4.5.tar.gz"
  sha256 "22861dba30b90d43b8623b71e5d02300968f1ef9f4fc341a6a0ce6dd315e8004"
  head "https://github.com/chengr28/Pcap_DNSProxy.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "741c8146733dffe379137cbce612537ae22e69a8b3d5a03c1bdf58d23549006a" => :el_capitan
    sha256 "0b81bfe38ace57eba6a7a5a5d8672999ff1fbebd9315e5d1a1b39b75e9cd8458" => :yosemite
    sha256 "33c919db4973f2fbb44f0e35a5d2c381744622f67b4dfe4bc97423b2b0a9c184" => :mavericks
  end

  depends_on :macos => :yosemite
  depends_on :xcode => :build
  depends_on "libsodium" => :build

  def install
    rm Dir[buildpath/"Source/LibSodium/*"]
    ln_s "#{Formula["libsodium"].opt_lib}/libsodium.a", "#{buildpath}/Source/LibSodium/LibSodium_Mac.a"
    ln_s Dir[Formula["libsodium"].opt_include/"*"], "#{buildpath}/Source/LibSodium/"
    xcodebuild "-project", "./Source/KeyPairGenerator.xcodeproj", "-target", "KeyPairGenerator", "-configuration", "Release", "SYMROOT=build"
    xcodebuild "-project", "./Source/FileHash.xcodeproj", "-target", "FileHash", "-configuration", "Release", "SYMROOT=build"
    xcodebuild "-project", "./Source/Pcap_DNSProxy.xcodeproj", "-target", "Pcap_DNSProxy", "-configuration", "Release", "SYMROOT=build"

    bin.install "Source/build/Release/KeyPairGenerator"
    bin.install "Source/build/Release/FileHash"
    bin.install "Source/build/Release/Pcap_DNSProxy"
    (etc/"pcap_DNSproxy").install Dir["Source/ExampleConfig/*.{ini,txt}"]
  end

  plist_options :startup => true, :manual => "sudo #{HOMEBREW_PREFIX}/opt/pcap_dnsproxy/bin/Pcap_DNSProxy -c #{HOMEBREW_PREFIX}/etc/pcap_dnsproxy/"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/Pcap_DNSProxy</string>
          <string>-c</string>
          <string>#{etc}/pcap_dnsproxy/</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
      </dict>
    </plist>
    EOS
  end

  test do
    (testpath/"pcap_dnsproxy").mkpath
    cp Dir[etc/"pcap_dnsproxy/*"], testpath/"pcap_dnsproxy/"

    inreplace testpath/"pcap_dnsproxy/Config.ini" do |s|
      s.gsub! /^Direct Request.*/, "Direct Request = IPv4 + IPv6"
      s.gsub! /^Operation Mode.*/, "Operation Mode = Proxy"
      s.gsub! /^Listen Port.*/, "Listen Port = 9999"
    end

    pid = fork { exec bin/"Pcap_DNSProxy", "-c", testpath/"pcap_dnsproxy/" }
    begin
      system "dig", "google.com", "@127.0.0.1", "-p", "9999", "+short"
    ensure
      Process.kill 9, pid
      Process.wait pid
    end
  end
end
