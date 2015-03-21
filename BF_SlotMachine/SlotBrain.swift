//
//  SlotBrain.swift
//  BF_SlotMachine
//
//  Created by Bruce Walker on 3/20/15.
//  Copyright (c) 2015 Bruce D Walker. All rights reserved.
//

import Foundation

struct Payouts {

    // Constants
    let kFlushMultiplier: Int = 1
    let k3OfKindMultiplier: Int = 3
    let kStraightMultiplier: Int = 1
    let kEpicFlushMultiplier: Int = 15
    let kEpic3OfKindMultiplier: Int = 50
    let kEpicStraightMultiplier: Int = 1000
}

class SlotBrain {

    class func unpackSlotsIntoRows(slotCols: [[Slot]]) -> [[Slot]] {
        // This function translates our slot cells into rows for calculating winnings
        var slotRows:[[Slot]] = [[]]
        for slotArray in slotCols
        {
            for (var n=0; n<slotArray.count; n++)
            {
                if (slotRows.count < n+1) { slotRows.append([]) }
                slotRows[n].append(slotArray[n])
            }
        }
        return slotRows
    }

    class func computeWinnings(slots: [[Slot]]) -> Int {

        // Local variables
        var nWinFactor = 0  // This will be our return value and will be a multiplier to determine winnings
        var nFlushCount = 0  // Count of the flushes (same color across row)
        var n3ofKindCount = 0  // Count of three of a kind (same value accross row)
        var nStraightCount = 0  // Count of straights (three adjacent cards in ascending or descending order)
        
        // Begin by translating slot cells into rows
        var slotRows = self.unpackSlotsIntoRows(slots)
        
        // Check each row for winning combinations
        for slotRow in slotRows
        {
            if self.isFlush(slotRow) { nFlushCount++ }
            if self.is3ofKind(slotRow) { n3ofKindCount++ }
            if self.isStraight(slotRow) { nStraightCount++ }
        }

        // Determine win factor
        var payouts = Payouts()
        nWinFactor = (nFlushCount * payouts.kFlushMultiplier) + (n3ofKindCount * payouts.k3OfKindMultiplier) + (nStraightCount * payouts.kStraightMultiplier)
        if (nFlushCount==3) { nWinFactor += payouts.kEpicFlushMultiplier }
        if (n3ofKindCount==3) { nWinFactor += payouts.kEpic3OfKindMultiplier }
        if (nStraightCount==3) { nWinFactor += payouts.kEpicStraightMultiplier }
        return nWinFactor
    }
    
    class func isFlush(row: [Slot]) -> Bool {
        // Check slot row for same color across all three cards
        var isFlush: Bool = true
        var bRed:Bool = row[0].isRed
        for (var n=1; n<row.count; n++)
        {
            if (row[n].isRed != bRed)
            {
                isFlush = false
                break
            }
        }
        return isFlush
    }
    
    class func is3ofKind(row: [Slot]) -> Bool {
        // Check slot row for same value across all three cards
        var is3ofKind: Bool = true
        var nValue:Int = row[0].value
        for (var n=1; n<row.count; n++)
        {
            if (row[n].value != nValue)
            {
                is3ofKind = false
                break
            }
        }
        return is3ofKind
    }
    
    class func isStraight(row: [Slot]) -> Bool {
        // Check slot row for three adjacent cards in ascending or descending order
        var isStraight: Bool = false
        if ( (row[0].value == row[1].value - 1 && row[1].value == row[2].value - 1) || (row[0].value == row[1].value + 1 && row[1].value == row[2].value + 1) )
        {
            isStraight = true
        }
        // Special case for Queen, King, Ace straights
        else if ( (row[0].value == 12 && row[1].value == 13 && row[2].value == 1) || (row[0].value == 1 && row[1].value == 13 && row[2].value == 12 ) )
        {
            isStraight = true
        }
        return isStraight
    }
}