//
//  AudioInfo.swift
//  HearingBuddy
//
//  Created by Soneé John on 12/15/21.
//

import Foundation

struct AudioDevice
{
    let name: String
    let isBluetooh: Bool
    let isInput: Bool
    let isOutput: Bool
    let isCurrentOutput: Bool
    let isExternalWiredHeadphones: Bool
    
    init?(info: [String : AnyObject]) {
        guard let name = info["_name"] as? String else { return nil }
        
        self.name = name
        self.isBluetooh = info["coreaudio_device_transport"].flatMap({ ($0 as? String)?.contains("coreaudio_device_type_bluetooth") }) ?? false
        self.isInput = info["coreaudio_device_input"] != nil
        self.isOutput = info["coreaudio_device_output"] != nil
        self.isCurrentOutput = info["_properties"].flatMap({ ($0 as? String)?.contains("coreaudio_default_audio_system_device") }) ?? false
        self.isExternalWiredHeadphones = info["coreaudio_output_source"].flatMap({ ($0 as? String)?.contains("Headphones") }) ?? false
    }
}

class AudioInfo
{
    static let shared = AudioInfo()
    
    func currentSystemOutputVolume() -> Int32
    {
        return NSAppleScript(source: "output volume of (get volume settings)")?.executeAndReturnError(nil).int32Value ?? 0
    }
    
    func setSystemOutputVolume(_ volume: Int32) -> Int32
    {
        NSAppleScript(source: "set volume output volume \(volume)")?.executeAndReturnError(nil).int32Value ?? 0
    }
    
    func outputDeviceAreHeadphonesOrBluetoothDevice () -> (Bool, AudioDevice?) {
        guard let devices = devices() else  {
            return (false, nil)
        }
        
        let device = devices.first { $0.isOutput == true && $0.isCurrentOutput == true && ( $0.isBluetooh || $0.isExternalWiredHeadphones) }
        return (device != nil, device)
    }
    
    func currentOutputDevice () -> AudioDevice? {
        guard let devices = devices() else  {
            return nil
        }
        
        return devices.first { $0.isOutput == true && $0.isCurrentOutput == true }
    }
    
    func devices () -> [AudioDevice]?
    {
        let process = Process()
        
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments =  ["-json", "SPAudioDataType"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try? process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else { return nil }
        let read = pipe.fileHandleForReading
        guard let data = try? read.readToEnd() else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed) as? [String : Any] else { return nil }
        guard let audioDataType = json["SPAudioDataType"] as? [AnyObject] else { return nil }
        guard let root = audioDataType.first as? [String : AnyObject] else { return nil }
        guard let items = root["_items"] as? [[String : AnyObject]] else { return nil }
        
        var audioDevices: [AudioDevice] = []
        
        items.forEach { device in
            guard let audioDevice = AudioDevice(info: device) else { return }
            audioDevices.append(audioDevice)
        }
        
        return audioDevices
    }
}
