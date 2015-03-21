//
//  Factory.swift
//  BF_SlotMachine
//
//  Created by Bruce Walker on 3/19/15.
//  Copyright (c) 2015 Bruce D Walker. All rights reserved.
//

import Foundation
import UIKit

class Factory {
    class func createSlots() -> [[Slot]] {
        // Create an array of three arrays of three slots each
        let kSlotColumns = 3
        let kSlotRows = 3
        
        var slots: [[Slot]] = []
        for (var nCol=0; nCol<kSlotColumns; nCol++)
        {
            var slotRow: [Slot] = []
            for (var nRow=0; nRow<kSlotRows; nRow++)
            {
                var slot = Factory.createSlot(slotRow)
                slotRow.append(slot)
            }
            slots.append(slotRow)
        }
        return slots
    }
    
    class func createSlot(currentCards: [Slot]) -> Slot {
        // Generates one slot cell
        
        // Generate an array of values from the currentCards array
        // We will use these values to ensure the same card doesn't appear twice in the same column
        var currentCardsValues:[Int] = []
        for slot in currentCards
        {
            currentCardsValues.append(slot.value)
        }
        
        // Generate a random number from 1 - 13, but ensure that number doesn't exist in currentCardValues
        var nRandom:Int
        do {
            nRandom = Int(arc4random_uniform(UInt32(13))) + 1
        } while contains(currentCardsValues, nRandom)
        
        // Generate our slot based on the random value generated
        var slot:Slot
        switch (nRandom)
        {
        case 1:
            slot = Slot(value: 1, image: UIImage(named: "Ace"), isRed: true)
        case 2:
            slot = Slot(value: 2, image: UIImage(named: "Two"), isRed: true)
        case 3:
            slot = Slot(value: 3, image: UIImage(named: "Three"), isRed: true)
        case 4:
            slot = Slot(value: 4, image: UIImage(named: "Four"), isRed: true)
        case 5:
            slot = Slot(value: 5, image: UIImage(named: "Five"), isRed: false)
        case 6:
            slot = Slot(value: 6, image: UIImage(named: "Six"), isRed: false)
        case 7:
            slot = Slot(value: 7, image: UIImage(named: "Seven"), isRed: true)
        case 8:
            slot = Slot(value: 8, image: UIImage(named: "Eight"), isRed: false)
        case 9:
            slot = Slot(value: 9, image: UIImage(named: "Nine"), isRed: false)
        case 10:
            slot = Slot(value: 10, image: UIImage(named: "Ten"), isRed: true)
        case 11:
            slot = Slot(value: 11, image: UIImage(named: "Jack"), isRed: false)
        case 12:
            slot = Slot(value: 12, image: UIImage(named: "Queen"), isRed: false)
        case 13:
            slot = Slot(value: 13, image: UIImage(named: "King"), isRed: true)
        default:
            slot = Slot(value: 0, image: UIImage(named: ""), isRed: true)
        }
        
        return slot
    }
}