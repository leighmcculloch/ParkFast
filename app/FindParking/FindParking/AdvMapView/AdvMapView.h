//
//  AdvMapView.h
//  FindParking
//
//  Created by Leigh McCulloch on 24/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AdvMapViewPagingView.h"
#import "AdvMapViewItem.h"

@class AdvMapView;

@protocol AdvMapViewDelegate <NSObject>

- (void)advMapViewFocusCoordinateChanged:(AdvMapView*)advMapView;
- (void)advMapView:(AdvMapView*)advMapView regionDidChangeAnimated:(BOOL)animated;

@end

@interface AdvMapView : UIView<MKMapViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, AdvMapViewPagingViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) id<AdvMapViewDelegate> delegate;
@property (assign, nonatomic) CLLocationCoordinate2D focusCoordinate;
@property (retain, nonatomic) UIImage* imagePin;
@property (readonly, nonatomic) CLLocationCoordinate2D centerCoordinate;
@property (readonly, nonatomic) CGFloat spanMeters;
@property (readonly, nonatomic) CGFloat accuracy;

+ (AdvMapView*)viewFromNib;
- (void)addItem:(id<AdvMapViewItem>)item;
- (void)removeItem:(id<AdvMapViewItem>)item;
- (void)removeItemsNotRelevant;

@end
