//
//  ViewController.h
//  MACAPP1
//
//  Created by admindyn on 2018/3/23.
//  Copyright © 2018年 admindyn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

- (IBAction)deviceSelectedAc:(id)sender;

- (IBAction)rateSelectedAc:(id)sender;


@property (weak) IBOutlet NSPopUpButton *devicesSelected;

@property (weak) IBOutlet NSPopUpButton *rateSelected;

@property (weak) IBOutlet NSTextField *sendTextField;


@property (weak) IBOutlet NSButton *send;

- (IBAction)sendAction:(id)sender;

@property (weak) IBOutlet NSPopUpButton *lindEnding;


@property (weak) IBOutlet NSButton *openOrClose;


- (IBAction)openOrClosePort:(id)sender;


- (IBAction)cleartAC:(id)sender;


@property (unsafe_unretained) IBOutlet NSTextView *contentTV;

@property (unsafe_unretained) IBOutlet NSTextView *cStrContent;





@end

