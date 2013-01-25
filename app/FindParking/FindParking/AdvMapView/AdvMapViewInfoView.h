//
//  FPInfoView.h
//  FindParking
//
//  Created by Leigh McCulloch on 18/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AdvMapViewItem.h"

@interface AdvMapViewInfoView : UIView<UIActionSheetDelegate>

@property (retain, nonatomic) id<AdvMapViewItem> item;

+ (AdvMapViewInfoView*)infoViewWithItem:(id<AdvMapViewItem>)item;
- (void)updateLabels;
- (IBAction)showDirections:(id)sender;

@end
