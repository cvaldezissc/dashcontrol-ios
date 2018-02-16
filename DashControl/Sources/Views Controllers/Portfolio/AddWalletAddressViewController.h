//
//  AddWalletAddressViewController.h
//  DashControl
//
//  Created by Sam Westrich on 10/3/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class DCPersistenceStack;

@interface AddWalletAddressViewController : UITableViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) InjectedClass(DCPersistenceStack) stack;

@property (strong, nonatomic) IBOutlet UITextField * inputField;

-(IBAction)done:(id)sender;

@end
