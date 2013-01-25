//
//  AdvMapViewItem.h
//  FindParking
//
//  Created by Leigh McCulloch on 24/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol AdvMapViewItem <NSObject>

@property (readonly, nonatomic) NSString* identifier;
@property (assign  , nonatomic) NSUInteger order;
@property (readonly, nonatomic) NSString* title;
@property (readonly, nonatomic) NSString* subtitle1;
@property (readonly, nonatomic) NSString* subtitle2;
@property (readonly, nonatomic) CLLocationCoordinate2D coordinate;
@property (assign  , nonatomic) CLLocationDistance distance;

- (NSComparisonResult)comparePriority:(id<AdvMapViewItem>)other;

@end
