# typed: strict

class Homebrew::Cmd::PortablePackageCmd
  sig { returns(Homebrew::Cmd::PortablePackageCmd::Args) }
  def args; end
end

class Homebrew::Cmd::PortablePackageCmd::Args < Homebrew::CLI::Args
  sig { returns(T::Boolean) }
  def no_uninstall_deps?; end
end
