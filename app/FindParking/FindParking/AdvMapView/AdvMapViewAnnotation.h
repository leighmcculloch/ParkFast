//
//  AdvMapViewAnnotation.h
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "AdvMapViewItem.h"

@interface AdvMapViewAnnotation : NSObject<MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) id<AdvMapViewItem> item;

-(id)initWithItem:(id<AdvMapViewItem>)item;

- (NSString *)subtitle;
- (NSString *)title;

@end