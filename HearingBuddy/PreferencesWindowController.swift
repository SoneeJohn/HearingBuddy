//
//  PreferencesWindowController.swift
//  HearingBuddy
//
//  Created by Soneé John on 12/16/21.
//

import Cocoa

class PreferencesWindowController: NSWindowController {

    @IBOutlet weak var slider: NSSlider!
    @IBOutlet weak var label: NSTextField!
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        updateLabelIfNeeded()
        slider.doubleValue = Double(UserDefaults.standard.reduceLoudSoundsLimit)
    }
    
    @IBAction func changeSliderValue(_ sender: NSSlider) {
        UserDefaults.standard.reduceLoudSoundsLimit = sender.integerValue
        updateLabelIfNeeded()
    }
    
    func updateLabelIfNeeded () {
        label.stringValue = "\(UserDefaults.standard.reduceLoudSoundsLimit)%"
    }
}
