import Flutter
import UIKit
import AVFoundation

public class SwiftFlutterTtsPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
  private let logPrefix = "[FlutterTTS]"
  let iosAudioCategoryKey = "iosAudioCategoryKey"
  let iosAudioCategoryOptionsKey = "iosAudioCategoryOptionsKey"
  let iosAudioModeKey = "iosAudioModeKey"

  let synthesizer = AVSpeechSynthesizer()
  var rate: Float = AVSpeechUtteranceDefaultSpeechRate
  var volume: Float = 1.0
  var pitch: Float = 1.0
  var voice: AVSpeechSynthesisVoice?
  var awaitSpeakCompletion: Bool = false
  var awaitSynthCompletion: Bool = false
  var autoStopSharedSession: Bool = true
  var speakResult: FlutterResult? = nil
  var synthResult: FlutterResult? = nil
  private var hasLoggedAccessibilityDefaults = false
  private var loggedVoiceLanguages = Set<String>()
  
  lazy var audioSession = AVAudioSession.sharedInstance()
  lazy var language: String = {
    AVSpeechSynthesisVoice.currentLanguageCode()
  }()
  lazy var languages: Set<String> = {
    Set(AVSpeechSynthesisVoice.speechVoices().map(\.language))
  }()
    

  var channel = FlutterMethodChannel()
  init(channel: FlutterMethodChannel) {
    super.init()
    self.channel = channel
    synthesizer.delegate = self
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_tts", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterTtsPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "speak":
      let text: String = call.arguments as! String
      self.speak(text: text, result: result)
      break
    case "awaitSpeakCompletion":
      self.awaitSpeakCompletion = call.arguments as! Bool
      result(1)
      break
    case "awaitSynthCompletion":
      self.awaitSynthCompletion = call.arguments as! Bool
      result(1)
      break
    case "synthesizeToFile":
      guard let args = call.arguments as? [String: Any] else {
        result("iOS could not recognize flutter arguments in method: (sendParams)")
        return
      }
      let text = args["text"] as! String
      let fileName = args["fileName"] as! String
      let isFullPath = args["isFullPath"] as! Bool
      self.synthesizeToFile(text: text, fileName: fileName, isFullPath: isFullPath, result: result)
      break
    case "pause":
      self.pause(result: result)
      break
    case "setLanguage":
      let language: String = call.arguments as! String
      self.setLanguage(language: language, result: result)
      break
    case "setSpeechRate":
      let rate: Double = call.arguments as! Double
      self.setRate(rate: Float(rate))
      result(1)
      break
    case "setVolume":
      let volume: Double = call.arguments as! Double
      self.setVolume(volume: Float(volume), result: result)
      break
    case "setPitch":
      let pitch: Double = call.arguments as! Double
      self.setPitch(pitch: Float(pitch), result: result)
      break
    case "stop":
      self.stop()
      result(1)
      break
    case "getLanguages":
      self.getLanguages(result: result)
      break
    case "getSpeechRateValidRange":
      self.getSpeechRateValidRange(result: result)
      break
    case "isLanguageAvailable":
      let language: String = call.arguments as! String
      self.isLanguageAvailable(language: language, result: result)
      break
    case "getVoices":
      self.getVoices(result: result)
      break
    case "setVoice":
      guard let args = call.arguments as? [String: String] else {
        result("iOS could not recognize flutter arguments in method: (sendParams)")
        return
      }
      self.setVoice(voice: args, result: result)
      break
    case "clearVoice":
      self.clearVoice()
      result(1)
      break
    case "setSharedInstance":
      let sharedInstance = call.arguments as! Bool
      self.setSharedInstance(sharedInstance: sharedInstance, result: result)
      break
    case "autoStopSharedSession":
      let autoStop = call.arguments as! Bool
      self.autoStopSharedSession = autoStop
      result(1)
      break
    case "setIosAudioCategory":
      guard let args = call.arguments as? [String: Any] else {
        result("iOS could not recognize flutter arguments in method: (sendParams)")
        return
      }
      let audioCategory = args["iosAudioCategoryKey"] as? String
      let audioOptions = args[iosAudioCategoryOptionsKey] as? Array<String>
      let audioModes = args[iosAudioModeKey] as? String
      self.setAudioCategory(audioCategory: audioCategory, audioOptions: audioOptions, audioMode: audioModes, result: result)
      break
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func speak(text: String, result: @escaping FlutterResult) {
    if (self.synthesizer.isPaused) {
      if (self.synthesizer.continueSpeaking()) {
        if self.awaitSpeakCompletion {
          self.speakResult = result
        } else {
          result(1)
        }
      } else {
        result(0)
      }
    } else {
      let utterance = AVSpeechUtterance(string: text)
      // Ensure audio session is set for playback on real devices so TTS is audible
      do {
        try audioSession.setCategory(.playback, options: [])
        try audioSession.setActive(true)
      } catch {
        logMessage("AVAudioSession setup error: \(error)")
      }

      let assistiveApplied = applyAssistivePreferencesIfAvailable(utterance)
      if !assignVoice(to: utterance, assistiveApplied: assistiveApplied) {
        logMessage("speak(): letting system voice decide for language \(self.language)")
      }
      utterance.rate = self.rate
      utterance.volume = self.volume
      utterance.pitchMultiplier = self.pitch
      logMessage("speak(): text length=\(text.count), rate=\(self.rate), pitch=\(self.pitch), volume=\(self.volume)")

      self.synthesizer.speak(utterance)
      if self.awaitSpeakCompletion {
        self.speakResult = result
      } else {
        result(1)
      }
    }
  }

  private func synthesizeToFile(text: String, fileName: String, isFullPath: Bool, result: @escaping FlutterResult) {
    var output: AVAudioFile?
    var failed = false
    let utterance = AVSpeechUtterance(string: text)

    // Ensure audio session is set for playback on real devices
    do {
      try audioSession.setCategory(.playback, options: [])
      try audioSession.setActive(true)
    } catch {
      logMessage("AVAudioSession setup error: \(error)")
    }

    let assistiveApplied = applyAssistivePreferencesIfAvailable(utterance)
    if !assignVoice(to: utterance, assistiveApplied: assistiveApplied) {
      logMessage("synthesizeToFile(): letting system voice decide for language \(self.language)")
    }
    utterance.rate = self.rate
    utterance.volume = self.volume
    utterance.pitchMultiplier = self.pitch

    if #available(iOS 13.0, *) {
      self.synthesizer.write(utterance) { (buffer: AVAudioBuffer) in
        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
          // suppressed unknown buffer type log
          failed = true
          return
        }
        // suppressed verbose output
        if pcmBuffer.frameLength == 0 {
            // finished
        } else {
          // append buffer to file
          let fileURL: URL
          if isFullPath {
              fileURL = URL(fileURLWithPath: fileName)
          } else {
              fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
          }
          // suppressed saving-to-file log

        if output == nil {
          do {
            if #available(iOS 17.0, *) {
                guard let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: pcmBuffer.format.sampleRate, channels: 1, interleaved: false) else {
                // suppressed audio format creation error log
                failed = true
                return
              }
              output = try AVAudioFile(forWriting: fileURL, settings: audioFormat.settings)
            } else {
              output = try AVAudioFile(forWriting: fileURL, settings: pcmBuffer.format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            }
          } catch {
            // suppressed AVAudioFile creation error log
            failed = true
            return
          }
        }


          try! output!.write(from: pcmBuffer)
        }
      }
    } else {
        result("Unsupported iOS version")
    }
    if failed {
        result(0)
    }
    if self.awaitSynthCompletion {
      self.synthResult = result
    } else {
      result(1)
    }
  }

  private func pause(result: FlutterResult) {
      if (self.synthesizer.pauseSpeaking(at: AVSpeechBoundary.word)) {
        result(1)
      } else {
        result(0)
      }
  }

  private func setLanguage(language: String, result: FlutterResult) {
    if !(self.languages.contains(where: {$0.range(of: language, options: [.caseInsensitive, .anchored]) != nil})) {
      logMessage("setLanguage(\(language)) -> not available")
      result(0)
    } else {
      self.language = language
      self.voice = nil
      logMessage("setLanguage(\(language)) succeeded; cleared explicit voice to honor system preference")
      result(1)
    }
  }

  private func setRate(rate: Float) {
    self.rate = rate
  }

  private func setVolume(volume: Float, result: FlutterResult) {
    if (volume >= 0.0 && volume <= 1.0) {
      self.volume = volume
      result(1)
    } else {
      result(0)
    }
  }

  private func setPitch(pitch: Float, result: FlutterResult) {
    if (volume >= 0.5 && volume <= 2.0) {
      self.pitch = pitch
      result(1)
    } else {
      result(0)
    }
  }

  private func setSharedInstance(sharedInstance: Bool, result: FlutterResult) {
      do {
          try AVAudioSession.sharedInstance().setActive(sharedInstance)
          result(1)
      } catch {
          result(0)
      }
  }

  private func setAudioCategory(audioCategory: String?, audioOptions: Array<String>?, audioMode: String?, result: FlutterResult){
    let category: AVAudioSession.Category = AudioCategory(rawValue: audioCategory ?? "")?.toAVAudioSessionCategory() ?? audioSession.category
    let options: AVAudioSession.CategoryOptions = audioOptions?.reduce([], { (result, option) -> AVAudioSession.CategoryOptions in
      return result.union(AudioCategoryOptions(rawValue: option)?.toAVAudioSessionCategoryOptions() ?? [])}) ?? []
    do {
        if #available(iOS 12.0, *) {
            if audioMode == nil {
                try audioSession.setCategory(category, options: options)
            } else {
                let mode: AVAudioSession.Mode? = AudioModes(rawValue: audioMode ?? "")?.toAVAudioSessionMode() ?? AVAudioSession.Mode.default
                try audioSession.setCategory(category, mode: mode!, options: options)
            }
        } else {
            try audioSession.setCategory(category, options: options)
        }
      result(1)
    } catch {
      // suppressed error print
      result(0)
    }
  }

  private func stop() {
    self.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
  }

  private func getLanguages(result: FlutterResult) {
    result(Array(self.languages))
  }

  private func getSpeechRateValidRange(result: FlutterResult) {
    let validSpeechRateRange: [String:String] = [
      "min": String(AVSpeechUtteranceMinimumSpeechRate),
      "normal": String(AVSpeechUtteranceDefaultSpeechRate),
      "max": String(AVSpeechUtteranceMaximumSpeechRate),
      "platform": "ios"
    ]
    result(validSpeechRateRange)
  }

  private func isLanguageAvailable(language: String, result: FlutterResult) {
    var isAvailable: Bool = false
    if (self.languages.contains(where: {$0.range(of: language, options: [.caseInsensitive, .anchored]) != nil})) {
      isAvailable = true
    }
    result(isAvailable);
  }

  private func getVoices(result: FlutterResult) {
    if #available(iOS 9.0, *) {
      let voices = NSMutableArray()
      var voiceDict: [String: String] = [:]
      for voice in AVSpeechSynthesisVoice.speechVoices() {
        voiceDict["name"] = voice.name
        voiceDict["locale"] = voice.language
        voiceDict["quality"] = voice.quality.stringValue
        if #available(iOS 13.0, *) {
          voiceDict["gender"] = voice.gender.stringValue
        }
        voiceDict["identifier"] = voice.identifier
        voices.add(voiceDict)
      }
      result(voices)
    } else {
      // Since voice selection is not supported below iOS 9, make voice getter and setter
      // have the same bahavior as language selection.
      getLanguages(result: result)
    }
  }

    private func setVoice(voice: [String: String], result: FlutterResult) {
      logMessage("setVoice request: identifier=\(voice["identifier"] ?? ""), name=\(voice["name"] ?? ""), locale=\(voice["locale"] ?? "")")
      if #available(iOS 9.0, *) {
        // Check if identifier exists and is not empty
        if let identifier = voice["identifier"], !identifier.isEmpty {
          // Find the voice by identifier
          if let selectedVoice = AVSpeechSynthesisVoice(identifier: identifier) {
            self.voice = selectedVoice
            self.language = selectedVoice.language
            logVoiceSelection(selectedVoice, reason: "setVoice(): identifier match")
            result(1)
            return
          }
        }

        // If no valid identifier, search by name and locale, then prioritize by quality
        if let name = voice["name"], let locale = voice["locale"] {
          let matchingVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.name == name && $0.language == locale }

          if !matchingVoices.isEmpty {
            // Sort voices by quality: premium (if available) > enhanced > others
            let sortedVoices = matchingVoices.sorted { (voice1, voice2) -> Bool in
              let quality1 = voice1.quality
              let quality2 = voice2.quality

              // macOS 13.0+ supports premium quality
              if #available(iOS 16.0, *) {
                if quality1 == .premium {
                  return true
                } else if quality1 == .enhanced && quality2 != .premium {
                  return true
                } else {
                  return false
                }
              } else {
                // Fallback for macOS versions before 13.0 (no premium)
                if quality1 == .enhanced {
                  return true
                } else {
                  return false
                }
              }
            }

            // Select the highest quality voice
            if let selectedVoice = sortedVoices.first {
              self.voice = selectedVoice
              self.language = selectedVoice.language
              logVoiceSelection(selectedVoice, reason: "setVoice(): matched name+locale")
              result(1)
              return
            }
          }
        }

        // No matching voice found
        logMessage("setVoice(): unable to match requested voice; keeping existing configuration")
        result(0)
      } else {
        // Handle older iOS versions if needed
        setLanguage(language: voice["name"]!, result: result)
      }
  }

  private func clearVoice() {
    self.voice = nil
    logMessage("clearVoice(): removed explicit override; will defer to system preference")
  }

  private func logMessage(_ message: String) {
    // Logging disabled: no-op to avoid console output
  }

  private func logVoiceSelection(_ voice: AVSpeechSynthesisVoice?, reason: String) {
    // Logging disabled: no-op
  }

  private func emitDiagnostic(_ message: String) {
    // Diagnostic forwarding disabled
  }

  private func applyAssistivePreferencesIfAvailable(_ utterance: AVSpeechUtterance) -> Bool {
    if #available(iOS 14.0, *) {
      utterance.prefersAssistiveTechnologySettings = true
      logMessage("Assistive preferences enabled for language \(self.language)")
      return true
    }
    logMessage("Assistive preferences unavailable (< iOS 14); falling back to manual voice resolution")
    return false
  }

  @discardableResult
  private func assignVoice(to utterance: AVSpeechUtterance, assistiveApplied: Bool) -> Bool {
    if let selectedVoice = self.voice {
      utterance.voice = selectedVoice
      logVoiceSelection(selectedVoice, reason: "assignVoice(): explicitly selected voice")
      return true
    }

    if let preferredVoice = resolvePreferredVoice(allowSystemFallback: assistiveApplied) {
      utterance.voice = preferredVoice
      logVoiceSelection(preferredVoice, reason: "assignVoice(): resolved preferred voice")
      return true
    }

    return false
  }

  private func resolvePreferredVoice(allowSystemFallback: Bool) -> AVSpeechSynthesisVoice? {
    if let accessibilityVoice = accessibilityVoiceFromDefaults() {
      return accessibilityVoice
    }

    if let siriVoice = siriVoiceForLanguage() {
      return siriVoice
    }

    if let localeVoice = AVSpeechSynthesisVoice(language: self.language) {
      logVoiceSelection(localeVoice, reason: "resolvePreferredVoice(): locale match")
      return localeVoice
    }

    let fallbackLanguage = AVSpeechSynthesisVoice.currentLanguageCode()
    if fallbackLanguage != self.language,
       let fallbackVoice = AVSpeechSynthesisVoice(language: fallbackLanguage) {
      logVoiceSelection(fallbackVoice, reason: "resolvePreferredVoice(): using current locale fallback")
      return fallbackVoice
    }

    if allowSystemFallback {
      logMessage("resolvePreferredVoice(): no match found; deferring to system voice")
      return nil
    }

    let firstVoice = AVSpeechSynthesisVoice.speechVoices().first
    logVoiceSelection(firstVoice, reason: "resolvePreferredVoice(): defaulting to first voice in list")
    return firstVoice
  }

  private func accessibilityVoiceFromDefaults() -> AVSpeechSynthesisVoice? {
    let defaults = UserDefaults.standard
    let baseKey = "UIAccessibilitySpokenContentPreferredVoiceIdentifier"
    let languageVariants = [
      "\(baseKey)-\(self.language)",
      "\(baseKey)_\(self.language)",
      "\(baseKey).\(self.language)",
      "AXSpokenContentPreferredVoice_\(self.language)",
      "com.apple.speech.voice.identifier.\(self.language)",
      baseKey
    ]

    for key in languageVariants {
      if let identifier = defaults.string(forKey: key), !identifier.isEmpty {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
          logVoiceSelection(voice, reason: "accessibility defaults key \(key)")
          return voice
        } else {
          logMessage("accessibility defaults key \(key) provided missing identifier \(identifier)")
        }
      }
    }

    if let dict = defaults.dictionary(forKey: baseKey) as? [String: Any],
       let identifier = dict[self.language] as? String,
       !identifier.isEmpty,
       let voice = AVSpeechSynthesisVoice(identifier: identifier) {
      logVoiceSelection(voice, reason: "accessibility defaults dictionary entry")
      return voice
    }

    dumpAccessibilityVoiceDefaultsIfNeeded(defaults, baseKey: baseKey)
    return nil
  }

  private func dumpAccessibilityVoiceDefaultsIfNeeded(_ defaults: UserDefaults, baseKey: String) {
    if hasLoggedAccessibilityDefaults { return }
    hasLoggedAccessibilityDefaults = true
    
    let keywords = ["Voice", "Speech", "Siri", "Accessibility", "Spoken", "TTS", self.language]
    let snapshot = defaults.dictionaryRepresentation().filter { key, _ in
      keywords.contains { key.contains($0) }
    }
    
    if snapshot.isEmpty {
      logMessage("No UserDefaults keys matched any voice/speech keywords")
    } else {
      logMessage("=== UserDefaults keys containing voice/speech keywords: ===")
      for (key, value) in snapshot.sorted(by: { $0.key < $1.key }) {
        let valueStr = String(describing: value)
        let truncated = valueStr.count > 200 ? String(valueStr.prefix(200)) + "..." : valueStr
        logMessage("  \(key) = \(truncated)")
      }
      logMessage("=== End UserDefaults dump ===")
    }
  }

  private func siriVoiceForLanguage() -> AVSpeechSynthesisVoice? {
    let matchingVoices = AVSpeechSynthesisVoice.speechVoices().filter {
      $0.language.caseInsensitiveCompare(self.language) == .orderedSame
    }

    if !loggedVoiceLanguages.contains(self.language) {
      loggedVoiceLanguages.insert(self.language)
      logMessage("=== All available voices for \(self.language): ===")
      for voice in matchingVoices {
        var gender = "n/a"
        if #available(iOS 13.0, *) {
          gender = voice.gender.stringValue
        }
        logMessage("  • id=\(voice.identifier), name=\(voice.name), quality=\(voice.quality.stringValue), gender=\(gender)")
      }
      logMessage("=== End voice list ===")
    }

    // Premium voices first (highest quality)
    if #available(iOS 16.0, *) {
      let premiumVoices = matchingVoices.filter { $0.quality == .premium }
      if let voice = highestQualityVoice(from: premiumVoices) {
        logVoiceSelection(voice, reason: "resolvePreferredVoice(): premium quality voice selected")
        return voice
      }
    }

    // Enhanced voices second
    let enhancedVoices = matchingVoices.filter { $0.quality == .enhanced }
    if let voice = highestQualityVoice(from: enhancedVoices) {
      logVoiceSelection(voice, reason: "resolvePreferredVoice(): enhanced quality voice selected")
      return voice
    }

    // Siri voice pattern match (fallback, though Siri voices typically don't appear in API)
    let siriVoices = matchingVoices.filter { $0.identifier.lowercased().contains("siri") }
    if let voice = highestQualityVoice(from: siriVoices) {
      logVoiceSelection(voice, reason: "resolvePreferredVoice(): Siri identifier pattern match")
      return voice
    }

    return nil
  }

  private func highestQualityVoice(from voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
    guard !voices.isEmpty else { return nil }
    return voices.sorted { lhs, rhs in
      if lhs.quality == rhs.quality {
        return lhs.identifier < rhs.identifier
      }
      return lhs.quality.rawValue > rhs.quality.rawValue
    }.first
  }

  private func shouldDeactivateAndNotifyOthers(_ session: AVAudioSession) -> Bool {
    var options: AVAudioSession.CategoryOptions = .duckOthers
    if #available(iOS 9.0, *) {
      options.insert(.interruptSpokenAudioAndMixWithOthers)
    }
    options.remove(.mixWithOthers)

    return !options.isDisjoint(with: session.categoryOptions)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    if shouldDeactivateAndNotifyOthers(audioSession) && self.autoStopSharedSession {
      do {
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
      } catch {
        // suppressed error print
      }
    }
    if self.awaitSpeakCompletion && self.speakResult != nil {
        self.speakResult!(1)
        self.speakResult = nil
    }
    if self.awaitSynthCompletion && self.synthResult != nil {
      self.synthResult!(1)
      self.synthResult = nil
    }
    self.channel.invokeMethod("speak.onComplete", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onStart", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onPause", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onContinue", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    self.channel.invokeMethod("speak.onCancel", arguments: nil)
  }

  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    let nsWord = utterance.speechString as NSString
    let data: [String:String] = [
      "text": utterance.speechString,
      "start": String(characterRange.location),
      "end": String(characterRange.location + characterRange.length),
      "word": nsWord.substring(with: characterRange)
    ]
    self.channel.invokeMethod("speak.onProgress", arguments: data)
  }

}

extension AVSpeechSynthesisVoiceQuality {
    var stringValue: String {
        switch self {
        case .default:
            return "default"
        case .premium:
            return "premium"
        case .enhanced:
            return "enhanced"
        }
    }
}

@available(iOS 13.0, *)
extension AVSpeechSynthesisVoiceGender {
    var stringValue: String {
        switch self {
        case .male:
            return "male"
        case .female:
            return "female"
        case .unspecified:
            return "unspecified"
        }
    }
}
