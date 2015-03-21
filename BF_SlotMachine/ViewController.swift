//
//  ViewController.swift
//  BF_SlotMachine
//
//  Created by Bruce Walker on 3/19/15.
//  Copyright (c) 2015 Bruce D Walker. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    // Constants
    let kMarginForSlotsView: CGFloat = 1.0
    let kMarginForSlot: CGFloat = 2.0
    let kButtonOffset: CGFloat = 10.0
    let kEighth: CGFloat = 1.0 / 8.0
    let kSixth: CGFloat = 1.0 / 6.0
    let kThird: CGFloat = 1.0 / 3.0
    let kHalf: CGFloat = 1.0 / 2.0
    
    let kSlotColumns = 3
    let kSlotRows = 3
    
    let kMaxBet = 5
    
    // Audio Player
    var audioPlayer = AVAudioPlayer()
    
    // View containers for our four distinct screen sections
    var viewTitleContainer: UIView!
    var viewSlotsContainer: UIView!
    var viewInfoContainer: UIView!
    var viewControlContainer: UIView!

    // Title Label
    var lblTitle: UILabel!
    
    // Information Labels
    var lblCredits: UILabel!
    var lblBet: UILabel!
    var lblPayout: UILabel!
    var lblCreditsTitle: UILabel!
    var lblBetTitle: UILabel!
    var lblPayoutTitle: UILabel!
    var btnPayoutTable: UIButton!
    
    // Controls
    var btnReset: UIButton!
    var btnBet1: UIButton!
    var btnBetMax: UIButton!
    var btnSpin: UIButton!
    var viewAutoBet: UIView!
    var lblAutoBetTitle: UILabel!
    var chkAutoBet: UISwitch!
    
    // Slots
    var slots:[[Slot]] = []

    // Status
    var nCredits = 0
    var nBet = 0
    var nPayout = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.blackColor()
        self.setupContainerViews()
        self.setupTitleContainer(self.viewTitleContainer)
        self.setupInfoContainer(self.viewInfoContainer)
        self.setupControlContainer(self.viewControlContainer)

        self.hardReset()
    }

    override func supportedInterfaceOrientations() -> Int
    {
        // Restrict interface to portrait mode
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Action functions

    func showPayoutTable(button: UIButton) {
        // Display the payout rates

        var payouts = Payouts()

        var strPayouts:String = ""
        strPayouts += "\r\nFlush: x\(payouts.kFlushMultiplier)"
        strPayouts += "\r\n3 of a Kind: x\(payouts.k3OfKindMultiplier)"
        strPayouts += "\r\nStraight: x\(payouts.kStraightMultiplier)"
        strPayouts += "\r\n\r\nBONUSES"
        strPayouts += "\r\n3 Flushes: x\(payouts.kEpicFlushMultiplier)"
        strPayouts += "\r\n3 Triples: x\(payouts.kEpic3OfKindMultiplier)"
        strPayouts += "\r\n3 Straights: x\(payouts.kEpicStraightMultiplier)"
        
        self.showAlertWithText(header: "Payouts", message: strPayouts)
    }
    
    func resetButtonPressed(button: UIButton) {
        // If a bet has been placed, Reset only resets the current bet
        if (nBet > 0)
        {
            nCredits += nBet
            nBet = 0
            nPayout = 0
            self.updateInfoContainer()
        }
        // If current bet is 0, reset resets the entire game
        else
        {
            self.hardReset()
        }
    }
    
    func bet1Pressed(button: UIButton) {
        // If out of credits, give warning to reset game
        if (nCredits<=0)
        {
            self.showAlertWithText(header: "No Credits", message: "You are out of credits to bet. Please reset game for more credits.")
        }
        else
        {
            // If current bet is less than max bet, transfer one credit to bet
            if (nBet < kMaxBet)
            {
                nBet += 1
                nCredits -= 1
                nPayout = 0
                self.updateInfoContainer()
            }
            // If max bet already reached, show alert
            else
            {
                self.showAlertWithText(header: "Max Bet Reached", message: "You can only bet \(kMaxBet) credits at a time.")
            }
        }
    }
    
    func betMaxPressed(button: UIButton) {
        // If out of credits, give warning to reset game
        if (nCredits<=0)
        {
            self.showAlertWithText(header: "No Credits", message: "You are out of credits to bet. Please reset game for more credits.")
        }
        else
        {
            // Determine difference between current bet and max bet
            var nNewBet = kMaxBet - nBet
            // If we are not yet at max bet proceed
            if (nNewBet > 0)
            {
                // If credits is less than needed to reach max bet, just bet what we have
                if (nCredits < nNewBet)
                {
                    nNewBet = nCredits
                }
                // Transfer the additional bet from credits to bet
                nBet += nNewBet
                nCredits -= nNewBet
                nPayout = 0
                self.updateInfoContainer()
            }
            // If max bet already reached, show alert
            else
            {
                self.showAlertWithText(header: "Max Bet Reached", message: "You can only bet \(kMaxBet) credits at a time.")
            }
        }
    }
    
    func spinPressed(button: UIButton) {
        
        // Reset Payout
        nPayout = 0
        self.updateInfoContainer()

        // Bet Placed?
        if (nBet == 0)
        {
            showAlertWithText(header: "Place Bet", message: "You must place a bet to spin.")
        }
        else
        {
            // clear our slots array
            slots.removeAll(keepCapacity: true)
            
            // Build new slots array
            slots = Factory.createSlots()
            
            // Remove old card images and add new ones
            self.removeSlotImageViews()
            self.setupSlotsContainer(self.viewSlotsContainer)
            
            // Calculate payout and adjust credits
            nPayout = nBet * SlotBrain.computeWinnings(slots)
            nCredits += nPayout
            if ( nPayout > 0)
            {
                self.playAudioResource("payout.wav")
            }
            
            // Adjust bet based on auto bet switch
            if (!self.chkAutoBet.on)
            {
                nBet = 0
            }
            else
            {
                if (nCredits < nBet)
                {
                    nBet = nCredits
                }
                nCredits -= nBet
            }
            
            self.updateInfoContainer()
        }
    }

    // Helper Functions
    
//    func delay(delay:Double, closure:()->()) {
//        dispatch_after(
//            dispatch_time(
//                DISPATCH_TIME_NOW,
//                Int64(delay * Double(NSEC_PER_SEC))
//            ),
//            dispatch_get_main_queue(), closure)
//    }
    
    func updateInfoContainer() {
        
        // Update the screen with the current credits, bet and payout values
        self.lblCredits.text = "\(nCredits)"
        self.lblBet.text = "\(nBet)"
        self.lblPayout.text = "\(nPayout)"
        
        if (nPayout > 0)
        {
            self.lblPayout.backgroundColor = UIColor.yellowColor()
        }
        else
        {
            self.lblPayout.backgroundColor = self.lblBet.backgroundColor
        }
        
        // Set reset button text based on bet > 0
        if (nBet > 0)
        {
            self.btnReset.setTitle("Reset Bet", forState: UIControlState.Normal)
            self.btnReset.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            self.btnReset.backgroundColor = UIColor.cyanColor()
        }
        else
        {
            self.btnReset.setTitle("Reset Game", forState: UIControlState.Normal)
            self.btnReset.setTitleColor(UIColor.yellowColor(), forState: UIControlState.Normal)
            self.btnReset.backgroundColor = UIColor.purpleColor()
        }
    }
    
    func showAlertWithText(header: String = "Warning", message: String ) {
        var alert = UIAlertController(title: header, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil )
    }
    
    func playAudioResource( strResource: String ) {
        if var strAudioPath = NSBundle.mainBundle().pathForResource(strResource.stringByDeletingPathExtension, ofType:strResource.stringByReplacingOccurrencesOfString(strResource.stringByDeletingPathExtension+".", withString: "", options: nil, range: nil))
        {
            var urlAudioPath = NSURL.fileURLWithPath(strAudioPath)
            audioPlayer = AVAudioPlayer(contentsOfURL: urlAudioPath, error: nil)
            audioPlayer.enableRate = true
        } else {
            println("file path is empty")
        }
        self.audioPlayer.prepareToPlay()
        self.audioPlayer.play()
    }
    
    func removeSlotImageViews() {
        // Verify the slots container exists
        if (self.viewSlotsContainer != nil)
        {
            let container: UIView? = self.viewSlotsContainer!
            
            // Remove all the sub views (the only thing that should be in this container
            // are the 9 image views so we remove all sub views
            let subviews:Array? = container!.subviews
            for view in subviews!
            {
                view.removeFromSuperview()
            }
        }
    }
    
    func hardReset() {
        
        // Remove all image views from slots container
        self.removeSlotImageViews()
        
        // clear our slots array
        slots.removeAll(keepCapacity: true)
        
        // redraw the initial slots container
        self.setupSlotsContainer(self.viewSlotsContainer)
        
        // Reset credits, bet and payout then update screen
        self.nCredits = 50
        self.nPayout = 0
        self.nBet = 0
        self.updateInfoContainer()
    }
    
    // Setup functions
    
    func setupContainerViews() {
        // Setup title container
        self.viewTitleContainer = UIView(frame: CGRect(x: self.view.bounds.origin.x, y: self.view.bounds.origin.y, width: self.view.bounds.width, height: self.view.bounds.height * kEighth))
        self.viewTitleContainer.backgroundColor = UIColor.redColor()
        self.view.addSubview(self.viewTitleContainer)

        // Setup slots container
        self.viewSlotsContainer = UIView(frame: CGRect(x: self.view.bounds.origin.x + kMarginForSlotsView, y: self.viewTitleContainer.frame.height, width: self.view.bounds.width - ( kMarginForSlotsView * 2.0 ), height: self.view.bounds.height * (5 * kEighth)))
        self.viewSlotsContainer.backgroundColor = UIColor.blackColor()
        self.view.addSubview(self.viewSlotsContainer)
        
        // Setup info/stats container
        self.viewInfoContainer = UIView(frame: CGRect(x: self.view.bounds.origin.x, y: self.viewTitleContainer.frame.height + self.viewSlotsContainer.frame.height, width: self.view.bounds.width, height: self.view.bounds.height * kEighth))
        self.viewInfoContainer.backgroundColor = UIColor.lightGrayColor()
        self.view.addSubview(self.viewInfoContainer)
        
        // Setup the control container
        self.viewControlContainer = UIView(frame: CGRect(x: self.view.bounds.origin.x, y: self.viewTitleContainer.frame.height + self.viewSlotsContainer.frame.height + self.viewInfoContainer.frame.height, width: self.view.bounds.width, height: self.view.bounds.height * kEighth))
        self.viewControlContainer.backgroundColor = UIColor.blackColor()
        self.view.addSubview(self.viewControlContainer)
    }
    
    func setupTitleContainer(containerView: UIView) {
        
        // Determine font size based on container size
        let kTitleFontSize = containerView.frame.height * 0.60
        
        // Setup the title label
        self.lblTitle = UILabel()
        self.lblTitle.text = "Super Slots "
        self.lblTitle.textColor = UIColor.yellowColor()
        self.lblTitle.font = UIFont(name: "Futura-Medium", size: kTitleFontSize)
        self.lblTitle.sizeToFit()
        self.lblTitle.center = containerView.center
        containerView.addSubview(self.lblTitle)
    }

    func setupSlotsContainer(containerView: UIView) {
        
        // Setup a 3x3 grid of image views
        for (var nCol=0; nCol<kSlotColumns; nCol++)
        {
            for (var nRow=0; nRow<kSlotRows; nRow++)
            {
                // Each slot cell will have an image view to display a card
                var imgSlotCell = UIImageView()
                // If we have populated our slots array, set the image accordingly
                if (self.slots.count != 0)
                {
                    let slotColumn = slots[nCol]
                    let slot = slotColumn[nRow]
                    imgSlotCell.image = slot.image
                }
                // Set the other image view attributes whether or not we have populated the slots array
                imgSlotCell.contentMode = UIViewContentMode.ScaleAspectFit
                imgSlotCell.backgroundColor = UIColor.darkGrayColor()
                imgSlotCell.frame = CGRect(x: 1.0 + (containerView.bounds.origin.x + (CGFloat(nCol) * (containerView.bounds.size.width * kThird))), y: 1.0 + (containerView.bounds.origin.y + (CGFloat(nRow) * (containerView.frame.height * kThird))), width: (containerView.bounds.size.width * kThird) - kMarginForSlot, height: (containerView.frame.height * kThird) - kMarginForSlot)

                // Add the current image view to the slots container
                containerView.addSubview(imgSlotCell)
            }
            
        }
    }

    func setupInfoContainer(containerView: UIView) {

        // Set font sizes based on container size
        let kNumberFontSize = CGFloat(containerView.frame.height) * 0.22
        let kLabelFontSize = CGFloat(containerView.frame.height) * 0.18
        
        // Set up a color for the number label backgrounds
        let kNumberBGColor = UIColor(red: 0.5, green: 0.85, blue: 0.5, alpha: 1.0)

        // Setup label for displaying player's current credits
        self.lblCredits = UILabel()
        self.lblCredits.text = "000000"
        self.lblCredits.textColor = UIColor.redColor()
        self.lblCredits.backgroundColor = kNumberBGColor
        self.lblCredits.font = UIFont(name: "Menlo-Bold", size: kNumberFontSize)
        self.lblCredits.sizeToFit()
        self.lblCredits.bounds.size.width = (self.lblCredits.frame.width + CGFloat(10))
        self.lblCredits.bounds.size.height = (self.lblCredits.frame.height + CGFloat(4))
        self.lblCredits.center = CGPoint(x: containerView.frame.width * kSixth, y: containerView.frame.height * kThird)
        self.lblCredits.textAlignment = NSTextAlignment.Center
        containerView.addSubview(self.lblCredits)
        
        // Setup "CREDITS" label
        self.lblCreditsTitle = UILabel()
        self.lblCreditsTitle.text = "CREDITS"
        self.lblCreditsTitle.textColor = UIColor.blackColor()
        self.lblCreditsTitle.font = UIFont(name: "AmericanTypewriter", size: kLabelFontSize)
        self.lblCreditsTitle.sizeToFit()
        self.lblCreditsTitle.center = CGPoint(x: containerView.frame.width * kSixth, y: containerView.frame.height * (CGFloat(2.0) * kThird))
        self.lblCreditsTitle.textAlignment = NSTextAlignment.Center
        containerView.addSubview(self.lblCreditsTitle)
        
        // Setup label for displaying player's current bet
        self.lblBet = UILabel()
        self.lblBet.text = "000000"
        self.lblBet.textColor = UIColor.redColor()
        self.lblBet.backgroundColor = kNumberBGColor
        self.lblBet.font = UIFont(name: "Menlo-Bold", size: kNumberFontSize)
        self.lblBet.sizeToFit()
        self.lblBet.bounds.size.width = (self.lblBet.frame.width + CGFloat(10))
        self.lblBet.bounds.size.height = (self.lblBet.frame.height + CGFloat(4))
        self.lblBet.center = CGPoint(x: (containerView.frame.width * kSixth) + (containerView.frame.width * kThird), y: containerView.frame.height * kThird)
        self.lblBet.textAlignment = NSTextAlignment.Center
        containerView.addSubview(self.lblBet)

        // Setup "BET" label
        self.lblBetTitle = UILabel()
        self.lblBetTitle.text = "BET"
        self.lblBetTitle.textColor = UIColor.blackColor()
        self.lblBetTitle.font = UIFont(name: "AmericanTypewriter", size: kLabelFontSize)
        self.lblBetTitle.sizeToFit()
        self.lblBetTitle.center = CGPoint(x: (containerView.frame.width * kSixth) + (containerView.frame.width * kThird), y: containerView.frame.height * (CGFloat(2.0) * kThird))
        self.lblBetTitle.textAlignment = NSTextAlignment.Center
        containerView.addSubview(self.lblBetTitle)
        
        // Setup label for displaying player's current winnings
        self.lblPayout = UILabel()
        self.lblPayout.text = "000000"
        self.lblPayout.textColor = UIColor.redColor()
        self.lblPayout.backgroundColor = kNumberBGColor
        self.lblPayout.font = UIFont(name: "Menlo-Bold", size: kNumberFontSize)
        self.lblPayout.sizeToFit()
        self.lblPayout.bounds.size.width = (self.lblPayout.frame.width + CGFloat(10))
        self.lblPayout.bounds.size.height = (self.lblPayout.frame.height + CGFloat(4))
        self.lblPayout.center = CGPoint(x: (containerView.frame.width * kSixth) + (containerView.frame.width * CGFloat(2.0) * kThird), y: containerView.frame.height * kThird)
        self.lblPayout.textAlignment = NSTextAlignment.Center
        containerView.addSubview(self.lblPayout)

        // Setup "PAYOUT" label
        self.lblPayoutTitle = UILabel()
        self.lblPayoutTitle.text = "PAYOUT"
        self.lblPayoutTitle.textColor = UIColor.blackColor()
        self.lblPayoutTitle.font = UIFont(name: "AmericanTypewriter", size: kLabelFontSize)
        self.lblPayoutTitle.sizeToFit()
        self.lblPayoutTitle.center = CGPoint(x: (containerView.frame.width * kSixth) + (containerView.frame.width * CGFloat(2.0) * kThird), y: containerView.frame.height * (CGFloat(2.0) * kThird))
        self.lblPayoutTitle.textAlignment = NSTextAlignment.Center
        containerView.addSubview(self.lblPayoutTitle)

        // Setup the reset button
        self.btnPayoutTable = UIButton()
        self.btnPayoutTable.setTitle("(?)", forState: UIControlState.Normal)
        self.btnPayoutTable.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
        self.btnPayoutTable.titleLabel?.font = UIFont(name: "AmericanTypewriter", size: kLabelFontSize * 0.9)
        self.btnPayoutTable.sizeToFit()
        self.btnPayoutTable.bounds.size.height = (self.btnPayoutTable.frame.height - CGFloat(6))
        self.btnPayoutTable.center = CGPoint(x: (containerView.frame.width * kSixth) + (containerView.frame.width * CGFloat(2.0) * kThird) + (self.lblPayoutTitle.frame.width * 0.5) + (self.btnPayoutTable.frame.width * 0.5), y: containerView.frame.height * (CGFloat(2.0) * kThird) )
        self.btnPayoutTable.addTarget(self, action: "showPayoutTable:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(self.btnPayoutTable)
        
    }
    
    func setupControlContainer(containerView: UIView) {
        
        // Set font sizes based on container size
        let kButtonFontSize = CGFloat(containerView.frame.height) * 0.18

        // Setup the reset button
        self.btnReset = UIButton()
        self.btnReset.setTitle("Reset Game", forState: UIControlState.Normal)
        self.btnReset.setTitleColor(UIColor.yellowColor(), forState: UIControlState.Normal)
        self.btnReset.titleLabel?.font = UIFont(name: "Noteworthy-Bold", size: kButtonFontSize)
        self.btnReset.backgroundColor = UIColor.purpleColor()
        self.btnReset.sizeToFit()
        self.btnReset.bounds.size.width = (self.btnReset.frame.width + CGFloat(10))
        self.btnReset.bounds.size.height = (self.btnReset.frame.height - CGFloat(6))
        self.btnReset.center = CGPoint(x: containerView.frame.width * kEighth + kButtonOffset, y: containerView.frame.height * (2.0 * kEighth))
        self.btnReset.addTarget(self, action: "resetButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(self.btnReset)

        // Setup the Bet 1 button
        self.btnBet1 = UIButton()
        self.btnBet1.setTitle("Bet 1", forState: UIControlState.Normal)
        self.btnBet1.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
        self.btnBet1.titleLabel?.font = UIFont(name: "Noteworthy-Bold", size: kButtonFontSize)
        self.btnBet1.backgroundColor = UIColor.yellowColor()
        self.btnBet1.sizeToFit()
        self.btnBet1.bounds.size.width = (self.btnBet1.frame.width + CGFloat(10))
        self.btnBet1.bounds.size.height = (self.btnBet1.frame.height - CGFloat(6))
        self.btnBet1.center = CGPoint(x: containerView.frame.width * (3.0 * kEighth) + kButtonOffset, y: containerView.frame.height * (2.0 * kEighth))
        self.btnBet1.addTarget(self, action: "bet1Pressed:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(self.btnBet1)

        // Setup the Bet Max button
        self.btnBetMax = UIButton()
        self.btnBetMax.setTitle("Bet Max", forState: UIControlState.Normal)
        self.btnBetMax.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
        self.btnBetMax.titleLabel?.font = UIFont(name: "Noteworthy-Bold", size: kButtonFontSize)
        self.btnBetMax.backgroundColor = UIColor.orangeColor()
        self.btnBetMax.sizeToFit()
        self.btnBetMax.bounds.size.width = (self.btnBetMax.frame.width + CGFloat(10))
        self.btnBetMax.bounds.size.height = (self.btnBetMax.frame.height - CGFloat(6))
        self.btnBetMax.center = CGPoint(x: containerView.frame.width * (5.0 * kEighth) + kButtonOffset, y: containerView.frame.height * (2.0 * kEighth))
        self.btnBetMax.addTarget(self, action: "betMaxPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(self.btnBetMax)

        // Setup the Spin button
        self.btnSpin = UIButton()
        self.btnSpin.setTitle("SPIN", forState: UIControlState.Normal)
        self.btnSpin.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        self.btnSpin.titleLabel?.font = UIFont(name: "Noteworthy-Bold", size: kButtonFontSize)
        self.btnSpin.backgroundColor = UIColor.greenColor()
        self.btnSpin.sizeToFit()
        self.btnSpin.bounds.size.width = (self.btnSpin.frame.width + CGFloat(10))
        self.btnSpin.bounds.size.height = (self.btnSpin.frame.height - CGFloat(6))
        self.btnSpin.center = CGPoint(x: containerView.frame.width * (7.0 * kEighth) + kButtonOffset, y: containerView.frame.height * (2.0 * kEighth))
        self.btnSpin.addTarget(self, action: "spinPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(self.btnSpin)
        
        // Setup Auto Bet Switch
        self.lblAutoBetTitle = UILabel()
        self.lblAutoBetTitle.text = "Automatically Repeat Bet"
        self.lblAutoBetTitle.textColor = UIColor.whiteColor()
        self.lblAutoBetTitle.font = UIFont(name: "AmericanTypewriter", size: kButtonFontSize)
        self.lblAutoBetTitle.textAlignment = NSTextAlignment.Left
        self.lblAutoBetTitle.sizeToFit()
        self.lblAutoBetTitle.center = CGPoint(x: ((containerView.frame.width * (5.0 * kEighth)) - (self.lblAutoBetTitle.frame.width * kHalf)), y: containerView.frame.height * (6.0 * kEighth))
        containerView.addSubview(self.lblAutoBetTitle)
        self.chkAutoBet = UISwitch()
        self.chkAutoBet.on = false
        self.chkAutoBet.transform = CGAffineTransformMakeScale(0.75, 0.75)
        self.chkAutoBet.center = CGPoint(x: (containerView.frame.width * (5.0 * kEighth) + self.chkAutoBet.frame.width), y: containerView.frame.height * (6.0 * kEighth))
        containerView.addSubview(self.chkAutoBet)
    }
}

