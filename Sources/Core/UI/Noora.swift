public import Noora

// ref. https://github.com/tuist/tuist/blob/4c5485de44ae48d12deaa76fd0b3ee3a4c088a6e/cli/Sources/TuistSupport/UI/Noora%2BTuist.swift
public extension Noora {
  /// Shared instance of Noora for `isimctl`
  @TaskLocal static var current = Noora()
}
