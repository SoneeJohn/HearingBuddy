//
//  AppDelegate.swift
//  HearingBuddy
//
//  Created by Soneé John on 12/15/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var statusItem: NSStatusItem
    var soundsLimitObserver: NSKeyValueObservation?
    var pollingTimer: Timer?
    
    enum StatusMenuItemTag: Int {
        case reduceLoadSounds = 4000
        case currentOutputDevice
    }
    
    static let ReduceLoudSoundsDefaultKey = "ReduceLoudSounds"
    static let ReduceLoudSoundsLimitDefaultKey = "ReduceLoudSoundsLimit"

    static let preferencesWindowController: PreferencesWindowController = {
        return PreferencesWindowController.init(windowNibName: "PreferencesWindowController")
    }()
    
    override init() {
        let menu = NSMenu()
        
        let currentDeviceMenutItem = NSMenuItem(title: "Current Output Device", action: nil, keyEquivalent: "")
        currentDeviceMenutItem.tag = StatusMenuItemTag.currentOutputDevice.rawValue
        menu.addItem(currentDeviceMenutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let menuItem = NSMenuItem(title: "Reduce Loud Sounds", action: #selector(self.toggleReduceAudio(sender:)), keyEquivalent: "")
        menuItem.tag = StatusMenuItemTag.reduceLoadSounds.rawValue
        menu.addItem(menuItem)
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(self.openPreferences(sender:)), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: ""))
        
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem.button?.title = UserDefaults.standard.bool(forKey: AppDelegate.ReduceLoudSoundsDefaultKey) ? "👂✅" : "👂❌"
        self.statusItem.menu = menu
    
        super.init()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        UserDefaults.standard.register(defaults: [AppDelegate.ReduceLoudSoundsDefaultKey : true, AppDelegate.ReduceLoudSoundsLimitDefaultKey : 25])

        self.pollingTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.timerDidFire), userInfo: nil, repeats: true)
        self.pollingTimer?.fire()
        
        soundsLimitObserver = UserDefaults.standard.observe(\.reduceLoudSoundsLimit, options: [.new], changeHandler: { _, _ in
            self.reduceAudioIfNeeded()
        })
        
        reduceAudioIfNeeded()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.tag == StatusMenuItemTag.reduceLoadSounds.rawValue {
            menuItem.state = UserDefaults.standard.bool(forKey: AppDelegate.ReduceLoudSoundsDefaultKey) == true ? NSControl.StateValue.on : NSControl.StateValue.off
        }
        return true
    }
    
    @objc func timerDidFire () {
        reduceAudioIfNeeded()
    }
    
    @objc func toggleReduceAudio(sender: NSMenuItem)
    {
        let isOn = UserDefaults.standard.bool(forKey: AppDelegate.ReduceLoudSoundsDefaultKey)
        
        UserDefaults.standard.set(!isOn, forKey: AppDelegate.ReduceLoudSoundsDefaultKey)
        sender.state = UserDefaults.standard.bool(forKey: AppDelegate.ReduceLoudSoundsDefaultKey) == true ? NSControl.StateValue.on : NSControl.StateValue.off
        reduceAudioIfNeeded()
    }
    
    @objc func openPreferences(sender: NSMenuItem)
    {
        AppDelegate.preferencesWindowController.window?.makeKeyAndOrderFront(nil)
        AppDelegate.preferencesWindowController.window?.center()
        NSApp.activate(ignoringOtherApps: true)

    }
    
    func reduceAudioIfNeeded () {
        if let menuItem = self.statusItem.menu?.item(withTag: StatusMenuItemTag.currentOutputDevice.rawValue) {
            menuItem.title = "Playing from: \(AudioInfo.shared.currentOutputDevice()?.name ?? "Unknown")"
        }
        self.statusItem.button?.title = UserDefaults.standard.bool(forKey: AppDelegate.ReduceLoudSoundsDefaultKey) ? "👂✅" : "👂❌"
        if UserDefaults.standard.bool(forKey: AppDelegate.ReduceLoudSoundsDefaultKey) && AudioInfo.shared.currentSystemOutputVolume() > UserDefaults.standard.reduceLoudSoundsLimit && AudioInfo.shared.outputDeviceAreHeadphonesOrBluetoothDevice().0 {
            NSSound.beep()
            _ = AudioInfo.shared.setSystemOutputVolume(Int32(UserDefaults.standard.reduceLoudSoundsLimit))
        }
    }
}

extension UserDefaults {
    @objc dynamic var reduceLoudSoundsLimit: Int {
        get { self.integer(forKey: AppDelegate.ReduceLoudSoundsLimitDefaultKey) }
        set { self.set(newValue, forKey: AppDelegate.ReduceLoudSoundsLimitDefaultKey) }
    }
}
